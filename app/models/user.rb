class User < ApplicationRecord
  has_many :interests, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :contents, through: :messages
  has_many :diary_entries, dependent: :destroy
  has_many :content_adjustments, dependent: :destroy
  has_one :demographic_data, dependent: :destroy
  belongs_to :local_authority, optional: true

  validates :phone_number, :first_name, :last_name, :child_birthday, :terms_agreed_at, :postcode, presence: true
  validates_uniqueness_of :phone_number
  validates_plausible_phone :phone_number
  validates :child_birthday, inclusion: {
    in: ->(_) { (Date.current - 27.months)...(Date.current - 3.months) }
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
            .limit(x)
        }
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
            .where.not(content_id: nil)
        }
      )
      .group("users.id")
      .having("COUNT(*) = 2")
  }
  scope :not_finished_content, -> {
    where.not(last_content_id: Content.order(:position).last&.id)
      .or(User.where(last_content_id: nil))
  }
  scope :with_latest_adjustment, -> {
    with(latest_adjustments: ContentAdjustment.select("DISTINCT ON (user_id) *").order("user_id, created_at DESC"))
      .joins("INNER JOIN latest_adjustments ON latest_adjustments.user_id = users.id")
  }
  scope :needs_adjustment_assessment, -> {
    with_latest_adjustment
      .where(latest_adjustments: {needs_adjustment: true, direction: "not_sure", adjusted_at: nil})
  }
  scope :completed_adjustment_assessment, -> {
    with_latest_adjustment
      .where.not("latest_adjustments.adjusted_at IS NULL")
  }
  scope :incomplete_adjustment_assessment, -> {
    with_latest_adjustment
      .where(latest_adjustments: {adjusted_at: nil, direction: nil})
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
      Rollbar.error("User in study could not be updated", user_info: attributes)
    end
  end

  def needs_content_group_suggestions?
    latest_adjustment&.needs_adjustment? && !latest_adjustment.direction.nil?
  end

  def needs_new_content_group?
    needs_content_group_suggestions? && 
      (
        (latest_adjustment.needs_younger_content? && latest_adjustment.number_down_options >= messages.last.body.to_i) ||
        (latest_adjustment.needs_older_content? && latest_adjustment.number_up_options >= messages.last.body.to_i)
      )
  end

  private

  def had_any_content_before?
    last_content_id.present?
  end

  def not_seen_content?(content)
    messages.none? { |m| m.content_id == content.id }
  end

  def find_next_unseen_content
    i = Content.find(last_content_id).position + 1

    loop do
      content = Content.find_by(position: i)
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
