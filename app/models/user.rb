class User < ApplicationRecord
  has_many :interests, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :contents, through: :messages
  has_many :diary_entries, dependent: :destroy
  has_many :content_adjustments, dependent: :destroy
  has_one :demographic_data, dependent: :destroy
  belongs_to :local_authority, optional: true

  validates :phone_number, :first_name, :last_name, :child_birthday, :terms_agreed_at, :postcode, presence: true
  validates :phone_number, uniqueness: true
  validates_plausible_phone :phone_number
  validates :child_birthday, inclusion: {
    in: ->(_) { (Date.current - 27.months)...(Date.current - 3.months) },
  }, on: :create
  phony_normalize :phone_number, default_country_code: "UK"

  accepts_nested_attributes_for :interests, :demographic_data

  scope :contactable, -> { where(contactable: true) }
  scope :opted_out, -> { where(contactable: false) }
  has_one :latest_adjustment, -> { order(created_at: :desc) }, class_name: "ContentAdjustment"
  scope :with_preference_for_day, ->(day) { where(day_preference: day) }
  scope :wants_morning_message, -> { where(hour_preference: "morning") }
  scope :wants_afternoon_message, -> { where(hour_preference: "afternoon") }
  scope :wants_evening_message, -> { where(hour_preference: "evening") }
  scope :no_hour_preference_message, -> { where(hour_preference: ["no_preference", nil]) }
  scope :not_nudged, -> { where(nudged_at: nil) }
  scope :not_clicked_last_x_messages, ->(x) {
    joins(:messages)
      .where(
        messages: {
          id: Message
            .select(:id)
            .where("messages.user_id = users.id")
            .where.not(content_id: nil)
            .where("body LIKE ?", "%https://thp-text.uk/m%")
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
    where.not(last_content_id: Content.order(:position).last&.id)
      .or(User.where(last_content_id: nil))
  }

  attribute :hour_preference,
    morning: "morning",
    afternoon: "afternoon",
    evening: "evening",
    no_preference: "no_preference"

  before_validation :set_uuid

  def child_age_in_months_today
    (Time.zone.now.year * 12 + Time.zone.now.month) - (child_birthday.year * 12 + child_birthday.month)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def next_content
    if had_any_content_before?
      find_next_unseen_content
    else
      Group.find_by(language: language).contents.where(age_in_months: child_age_in_months_today).min_by(&:position)
    end
  end

  def had_content_this_week?
    messages.any? { |m| m.created_at > 6.days.ago && m.content_id.present? }
  end

  def update_local_authority
    location = LocationGeocoder.new(postcode).geocode
    local_authority = LocalAuthority.find_or_create_by(name: location.state, country: location.country_code)
    local_authority.users << self
  rescue Geokit::Geocoders::GeocodeError
    nil
  end

  def is_in_study?
    stripped_postcode = postcode.gsub(/[[:space:]]/, "").downcase
    ResearchStudyUser.find_by(postcode: stripped_postcode, last_four_digits_phone_number: phone_number[-4..]).present?
  end

  def put_on_waitlist
    if update(contactable: false, restart_at: DateTime.new(2025, 9, 15))
      SendWaitlistMessageJob.perform_now(self)
    else
      Appsignal.report_error(StandardError.new("User in study could not be updated")) do
        Appsignal.add_tags(user_info: attributes)
      end
    end
  end

  private

  def had_any_content_before?
    last_content_id.present?
  end

  def not_seen_content?(content)
    messages.none? { |m| m.content_id == content.id }
  end

  def find_next_unseen_content
    contents = Group.find_by(language: language).contents
    i = contents.find(last_content_id).position + 1

    loop do
      content = contents.find_by(position: i)
      # Last message in series
      return nil if content.nil?
      # Next message
      return content if not_seen_content?(content) && !content.archived?
      i += 1
    end
  end

  def set_uuid
    return unless new_record? && uuid.nil?

    uuid = generate_uuid

    while User.exists?(uuid:)
      generate_uuid
    end
  end

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end
