class User < ApplicationRecord
  PROGRAMME_LENGTH = 52

  has_many :messages, dependent: :destroy
  has_many :contents, through: :messages
  has_many :survey_sends, dependent: :destroy
  has_many :surveys, through: :survey_sends
  belongs_to :local_authority, optional: true
  belongs_to :group

  validates :terms_agreed_at, :child_birthday, presence: true
  validates :phone_number, :postcode, presence: true, unless: :anonymised?
  validates :terms_agreed, acceptance: true, on: :create
  validates :phone_number, uniqueness: true, unless: :anonymised?
  validates_plausible_phone :phone_number, unless: :anonymised?
  phony_normalize :phone_number, default_country_code: "UK", unless: :anonymised?
  validate :child_is_correct_age?, on: :create
  validate :has_welsh_postcode?, on: :create

  attr_accessor :terms_agreed
  attr_accessor :skip_age_validation

  before_validation :assign_group_by_language, if: -> { new_record? || language_changed? }

  generates_token_for :profile_token, expires_in: 15.minutes
  generates_token_for :restart_token, expires_in: 2.days
  generates_token_for :survey_token

  scope :contactable, -> { where(contactable: true) }
  scope :opted_out, -> { where(contactable: false) }
  scope :with_preference_for_day, ->(day) { where(day_preference: day) }
  scope :wants_morning_message, -> { where(hour_preference: "morning") }
  scope :wants_afternoon_message, -> { where(hour_preference: "afternoon") }
  scope :wants_evening_message, -> { where(hour_preference: "evening") }
  scope :no_hour_preference_message, -> { where(hour_preference: ["no_preference", nil]) }
  scope :not_nudged, -> { where(nudged_at: nil) }
  scope :due_for_restart, -> { opted_out.where("restart_at < ?", Time.zone.now) }
  scope :not_clicked_last_x_messages, ->(x) {
    joins(:messages)
      .where(
        messages: {
          id: Message
            .select(:id)
            .where("messages.user_id = users.id")
            .where.not(content_id: nil)
            .where.not(link: nil)
            .order(created_at: :desc)
            .limit(x),
        },
      )
      .where(finished_content_at: nil)
      .group("users.id")
      .having("COUNT(CASE WHEN messages.clicked_at IS NULL THEN 1 END) = #{x.to_i}")
  }
  scope :received_two_or_eighteen_messages, -> {
    joins(:messages)
      .where(
        messages: {
          id: Message
            .select(:id)
            .where("messages.user_id = users.id")
            .where.not(content_id: nil),
        },
      )
      .where(finished_content_at: nil)
      .group("users.id")
      .having("COUNT(*) = 2 OR COUNT(*) = 18")
  }
  scope :with_four_messages_left, -> {
    joins(:messages)
      .where.not(programme_length: nil)
      .where(<<~SQL.squish)
        (SELECT COUNT(*) FROM messages WHERE messages.user_id = users.id AND messages.content_id IS NOT NULL) = users.programme_length - 4
      SQL
      .group("users.id")
  }
  scope :received_six_messages_without_bilingual_text, -> {
    where(sent_bilingual_text_at: nil)
      .joins(:messages)
      .where(
        messages: {
          id: Message
            .select(:id)
            .where("messages.user_id = users.id")
            .where.not(content_id: nil),
        },
      )
      .where(finished_content_at: nil)
      .group("users.id")
      .having("COUNT(*) >= 6")
  }
  scope :not_finished, -> {
    where(finished_content_at: nil)
  }
  scope :needs_survey_reminder, ->(survey_id) {
    joins(:survey_sends)
      .where(survey_sends: {completed_at: nil, survey_id: survey_id, sent_at: 2.days.ago..1.days.ago})
      .where.not(contactable: false)
      .distinct
  }

  attribute :hour_preference,
    morning: "morning",
    afternoon: "afternoon",
    evening: "evening",
    no_preference: "no_preference"

  def programme_message_count
    messages.where.not(content_id: nil).count
  end

  def finished_programme?
    if programme_length.present?
      programme_message_count >= programme_length || next_content.blank?
    else
      had_any_content_before? && next_content.blank?
    end
  end

  def child_age_in_months_today
    (Time.zone.now.year * 12 + Time.zone.now.month) - (child_birthday.year * 12 + child_birthday.month)
  end

  def next_content
    if had_any_content_before?
      find_next_unseen_content
    else
      group.contents.where(age_in_months: child_age_in_months_today).order(:position).first
    end
  end

  def had_content_this_week?
    messages.where("created_at > ?", 6.days.ago).where.not(content_id: nil).exists?
  end

  def update_local_authority
    location = LocationGeocoder.new(postcode).geocode
    local_authority = LocalAuthority.find_or_create_by(name: location.state, country: location.country_code)
    local_authority.users << self
  rescue Geokit::Geocoders::GeocodeError
    nil
  end

  def put_on_waitlist
    restart_date = child_birthday + 9.months
    if update(contactable: false, restart_at: restart_date)
      SendWaitlistMessageJob.perform_later(self)
    else
      Appsignal.report_error(StandardError.new("User could not be put on waitlist")) do
        Appsignal.add_tags(user_info: attributes)
      end
    end
  end

  def on_waitlist?
    !contactable && restart_at.present? && restart_at > Time.zone.now
  end

  def anonymise!
    return if anonymised?

    ActiveRecord::Base.transaction do
      update!(
        anonymised_at: Time.zone.now,
        first_name: nil,
        child_name: nil,
        phone_number: "anonymised",
      )

      messages.where.not(status: "received").update_all(body: nil)
    end
  rescue ActiveRecord::RecordInvalid => e
    Appsignal.report_error("User and associated messages failed to anonymise: #{e.message}") do
      Appsignal.add_tags(user_info: attributes)
    end
  end

  def anonymised?
    anonymised_at.present?
  end

  def self.report_expired_token(token)
    return if token.blank?

    payload_b64 = token.to_s.split("--").first
    return if payload_b64.blank?

    decoded = JSON.parse(Base64.urlsafe_decode64(payload_b64))
    rails_meta = decoded["_rails"] || {}
    return unless rails_meta["exp"]

    expired_at = Time.iso8601(rails_meta["exp"])
    return if expired_at >= Time.zone.now

    Appsignal.report_error(StandardError.new("User token expired")) do
      Appsignal.add_tags(
        token_purpose: rails_meta["pur"],
        expired_at: rails_meta["exp"],
        seconds_overdue: (Time.zone.now - expired_at).to_i,
      )
    end
  rescue
    nil
  end

  private

  def assign_group_by_language
    self.group = Group.find_by(language: language)
  end

  def had_any_content_before?
    last_content_id.present?
  end

  def not_seen_content?(content)
    messages.none? { |m| m.content_id == content.id }
  end

  def find_next_unseen_content
    last_position = Content.find(last_content_id).position
    seen_ids = messages.where.not(content_id: nil).select(:content_id)

    group
      .contents
      .active
      .where.not(id: seen_ids)
      .where("position > ?", last_position)
      .order(:position)
      .first
  end

  def has_welsh_postcode?
    return if postcode.blank?
    unless PostcodeService.valid_welsh_postcode?(postcode)
      errors.add(:postcode, :not_welsh)
    end
  end

  def child_is_correct_age?
    return if child_birthday.blank?
    errors.add(:child_birthday, :too_old) if child_birthday < 18.months.ago.to_date
    errors.add(:child_birthday, :too_young) if child_birthday > 9.months.ago.to_date && !skip_age_validation
  end
end
