class User < ApplicationRecord
  has_many :interests
  has_many :messages, dependent: :destroy
  has_many :contents, through: :messages
  validates :phone_number, :first_name, :last_name, :child_birthday, presence: true
  validates_uniqueness_of :phone_number
  phony_normalize :phone_number, default_country_code: "UK"

  accepts_nested_attributes_for :interests

  scope :contactable, -> { where(contactable: true) }
  scope :wants_morning_message, -> { where(timing: "morning") }
  scope :wants_afternoon_message, -> { where(timing: "afternoon") }
  scope :wants_evening_message, -> { where(timing: "evening") }
  scope :no_preference_message, -> { where(timing: ["no_preference", nil]) }

  enum timing: {
    morning: "morning",
    afternoon: "afternoon",
    evening: "evening",
    no_preference: "no_preference"
  }

  def child_age_in_months_today
    (Time.now.year * 12 + Time.now.month) - (child_birthday.year * 12 + child_birthday.month)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def next_content(group)
    return unless group.present?
    # find lowest ranked content minus any they have already seen
    (group.contents - contents).min_by(&:position)
  end
end
