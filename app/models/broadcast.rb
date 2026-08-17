class Broadcast < ApplicationRecord
  belongs_to :admin
  has_many :messages, dependent: :nullify
  has_many :users, through: :messages
  belongs_to :survey, optional: true

  USER_GROUPS = {
    welsh_pilot: "Users in Welsh Pilot",
    received_at_least_x_messages: "Users who have received at least X messages",
  }.freeze

  GROUPS_REQUIRING_MESSAGE_THRESHOLD = [:received_at_least_x_messages].freeze

  validates :body_en, presence: true
  validates :body_cy, presence: true
  validates :user_groups, presence: true
  validates :message_threshold, presence: true, numericality: {only_integer: true, greater_than: 0}, if: :requires_message_threshold?
  validate :user_groups_are_recognised
  validate :survey_present_if_survey_link_used

  def user_groups=(value)
    super(Array(value).reject(&:blank?))
  end

  def save_and_send!
    transaction do
      save!
      SendBroadcastJob.perform_later(self)
    end
  end

  def matching_users
    User.where(id: user_groups.flat_map { |group| resolve_group(group) }.uniq)
  end

  private

  def survey_present_if_survey_link_used
    return false unless body_en.present? && body_cy.present?

    if body_en.include?("{{survey_link}}") || body_cy.include?("{{survey_link}}")
      errors.add(:survey, "must be present if {{survey_link}} placeholder is used") unless survey.present?
    end
  end

  def requires_message_threshold?
    (user_groups.to_a.map(&:to_sym) & GROUPS_REQUIRING_MESSAGE_THRESHOLD).any?
  end

  def resolve_group(group)
    if GROUPS_REQUIRING_MESSAGE_THRESHOLD.map(&:to_s).include?(group.to_s)
      User.public_send(group, message_threshold).pluck(:id)
    else
      User.public_send(group).pluck(:id)
    end
  end

  def user_groups_are_recognised
    unrecognised = user_groups.to_a - USER_GROUPS.keys.map(&:to_s)
    errors.add(:user_groups, "includes an unrecognised group: #{unrecognised.join(", ")}") if unrecognised.any?
  end
end
