class User < ApplicationRecord
  has_many :interests, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :contents, through: :messages
  has_many :diary_entries, dependent: :destroy
  has_one :demographic_data, dependent: :destroy
  belongs_to :local_authority, optional: true

  validates :phone_number, :first_name, :last_name, :child_birthday, :terms_agreed_at, :postcode, presence: true
  validates_uniqueness_of :phone_number
  validates_plausible_phone :phone_number
  validates :child_birthday, inclusion: {in: ((Date.today - 27.months)...(Date.today - 3.months))}

  phony_normalize :phone_number, default_country_code: "UK"

  accepts_nested_attributes_for :interests, :demographic_data

  scope :contactable, -> { where(contactable: true) }
  scope :opted_out, -> { where(contactable: false) }
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
            .order(created_at: :desc)
            .limit(x)
        }
      )
      .group("users.id")
      .having("COUNT(CASE WHEN messages.clicked_at IS NULL THEN 1 END) = 2")
  }
  scope :received_two_messages, -> {
    joins(:messages)
      .where(
        messages: {
          id: Message
            .select(:id)
            .where("messages.user_id = users.id")
            .where.not(content_id: nil)
        }
      )
      .group("users.id")
      .having("COUNT(*) = 2")
  }
  scope :not_finished_content, -> {
    where.not(id: Message.select(:user_id).where(content_id: Content.order(:position).last&.id))
  }

  attribute :hour_preference,
    morning: "morning",
    afternoon: "afternoon",
    evening: "evening",
    no_preference: "no_preference"

  before_validation :set_uuid

  def child_age_in_months_today
    (Time.now.year * 12 + Time.now.month) - (child_birthday.year * 12 + child_birthday.month)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def next_content
    if had_any_content_before?
      find_next_unseen_content
    else
      Content.where(age_in_months: child_age_in_months_today).min_by(&:position)
    end
  end

  def had_content_this_week?
    messages.where("created_at > ?", 6.days.ago).where.not(content: nil).exists?
  end

  def update_local_authority
    location = LocationGeocoder.new(postcode).geocode
    local_authority = LocalAuthority.find_or_create_by(name: location.state)
    local_authority.users << self
  rescue Geokit::Geocoders::GeocodeError
    nil
  end

  private

  def had_any_content_before?
    last_content_id.present?
  end

  def not_seen_content?(content)
    messages.where(content_id: content.id).none?
  end

  def find_next_unseen_content
    i = Content.find(last_content_id).position + 1

    loop do
      content = Content.find_by(position: i)
      # Last message in series
      return nil if content.nil?
      # Next message
      return content if not_seen_content?(content)
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
