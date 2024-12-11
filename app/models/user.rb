class User < ApplicationRecord
  has_many :interests
  has_many :messages, dependent: :destroy
  has_many :contents, through: :messages

  validates :phone_number, :first_name, :last_name, :child_birthday, :terms_agreed_at, :postcode, presence: true
  validates_uniqueness_of :phone_number
  validates :child_birthday, inclusion: {in: ((Date.today - 5.years)...Date.today)}

  phony_normalize :phone_number, default_country_code: "UK"

  scope :contactable, -> { where(contactable: true) }
  scope :opted_out, -> { where(contactable: false) }
  scope :wants_morning_message, -> { where(hour_preference: "morning") }
  scope :wants_afternoon_message, -> { where(hour_preference: "afternoon") }
  scope :wants_evening_message, -> { where(hour_preference: "evening") }
  scope :no_preference_message, -> { where(hour_preference: ["no_preference", nil]) }
  scope :not_nudged, -> { where(nudged_at: nil) }
  scope :not_clicked_last_two_messages, -> {
    joins(:messages)
      .where(
        messages: {
          id: Message
            .select(:id)
            .where("messages.user_id = users.id")
            .where.not(content_id: nil)
            .order(created_at: :desc)
            .limit(2)
        }
      )
      .group("users.id")
      .having("COUNT(CASE WHEN messages.clicked_at IS NULL THEN 1 END) = 2")
  }

  attribute :hour_preference,
    morning: "morning",
    afternoon: "afternoon",
    evening: "evening",
    no_preference: "no_preference"

  def child_age_in_months_today
    (Time.now.year * 12 + Time.now.month) - (child_birthday.year * 12 + child_birthday.month)
  end

  def adjusted_child_age_in_months_today
    child_age_in_months_today + adjust_amount
  end

  def adjust_age
    new_amount = self.adjust_amount -= 1
    update(adjust_amount: new_amount)
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
end
