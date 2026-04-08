class User < ApplicationRecord
  has_many :messages, dependent: :destroy
  has_many :contents, through: :messages
  has_many :survey_sends, dependent: :destroy
  has_many :surveys, through: :survey_sends
  belongs_to :local_authority, optional: true
  belongs_to :group

  validates :phone_number, :child_birthday, :terms_agreed_at, :postcode, presence: true
  validates :terms_agreed, acceptance: true, on: :create
  validates :phone_number, uniqueness: true
  validates_plausible_phone :phone_number
  phony_normalize :phone_number, default_country_code: "UK"
  validate :child_is_correct_age?, on: :create
  validate :has_welsh_postcode?, on: :create

  attr_accessor :terms_agreed
  attr_accessor :skip_age_validation

  before_validation :assign_group_by_language, if: -> { new_record? || language_changed? }

  generates_token_for :profile_token, expires_in: 15.minutes
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
      .group("users.id")
      .having("COUNT(CASE WHEN messages.clicked_at IS NULL THEN 1 END) = #{x.to_i}")
  }
  scope :received_two_messages, -> {
    joins(:messages)
      .where(
        messages: {
          id: Message
            .select(:id)
            .where("messages.user_id = users.id")
            .where.not(content_id: nil),
        },
      )
      .group("users.id")
      .having("COUNT(*) = 2")
  }
  scope :not_finished_content, -> {
    last_content_per_group = Content.select("DISTINCT ON (group_id) id")
      .order("group_id, position DESC")
    joins(:group).where.not(last_content_id: last_content_per_group)
      .or(User.joins(:group).where(last_content_id: nil))
  }
  scope :needs_survey_reminder, ->(survey_id) {
    joins(:survey_sends)
      .where(survey_sends: {completed_at: nil, survey_id: survey_id, sent_at: 2.days.ago..1.days.ago})
  }

  attribute :hour_preference,
    morning: "morning",
    afternoon: "afternoon",
    evening: "evening",
    no_preference: "no_preference"

  def programme_message_count
    messages.where.not(content_id: nil).count
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
      SendWaitlistMessageJob.perform_now(self)
    else
      Appsignal.report_error(StandardError.new("User could not be put on waitlist")) do
        Appsignal.add_tags(user_info: attributes)
      end
    end
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
