class User < ApplicationRecord
  has_many :interests
  has_many :messages, dependent: :destroy
  has_many :contents, through: :messages

  validates :phone_number, :first_name, :last_name, :child_birthday, :terms_agreed_at, presence: true
  validates_uniqueness_of :phone_number
  validates :child_birthday, inclusion: {in: ((Date.today - 5.years)...Date.today)}

  phony_normalize :phone_number, default_country_code: "UK"

  scope :contactable, -> { where(contactable: true) }
  scope :opted_out, -> { where(contactable: false) }
  scope :wants_morning_message, -> { where(timing: "morning") }
  scope :wants_afternoon_message, -> { where(timing: "afternoon") }
  scope :wants_evening_message, -> { where(timing: "evening") }
  scope :no_preference_message, -> { where(timing: ["no_preference", nil]) }
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

  enum timing: {
    morning: "morning",
    afternoon: "afternoon",
    evening: "evening",
    no_preference: "no_preference"
  }

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

  def next_content(group)
    return unless group.present?
    # find lowest ranked content minus any they have already seen
    (group.weekly_content - contents).min_by(&:position)
  end

  def had_content_this_week?
    messages.where("created_at > ?", 6.days.ago).where.not(content: nil).exists?
  end
end
