class Broadcast < ApplicationRecord
  belongs_to :admin
  has_many :messages, dependent: :nullify
  has_many :users, through: :messages
  belongs_to :survey, optional: true

  validates :body_en, presence: true
  validates :body_cy, presence: true
  validates :recipient_ids, presence: true
  validate :recipient_ids_are_valid
  validate :recipient_ids_correspond_to_users
  validate :survey_present_if_survey_link_used

  def recipient_ids=(value)
    tokens = value.is_a?(String) ? value.split(/[\s,]+/) : Array(value)
    tokens = tokens.compact_blank.map(&:to_s)

    @invalid_recipient_id_tokens = tokens.reject { |token| token.match?(/\A\d+\z/) }
    valid_tokens = tokens - @invalid_recipient_id_tokens

    super(valid_tokens.map(&:to_i).uniq)
  end

  def save_and_send!
    transaction do
      save!
      SendBroadcastJob.perform_later(self)
    end
  end

  def matching_users
    User.contactable
      .where(anonymised_at: nil)
      .where(id: recipient_ids)
  end

  private

  def recipient_ids_are_valid
    return if @invalid_recipient_id_tokens.blank?

    errors.add(:recipient_ids, "includes values that aren't valid user ids: #{@invalid_recipient_id_tokens.join(", ")}")
  end

  def recipient_ids_correspond_to_users
    return if recipient_ids.blank?

    unknown_ids = recipient_ids - User.where(id: recipient_ids).pluck(:id)
    errors.add(:recipient_ids, "includes unknown user ids: #{unknown_ids.join(", ")}") if unknown_ids.any?
  end

  def survey_present_if_survey_link_used
    return false unless body_en.present? && body_cy.present?

    if body_en.include?("{{survey_link}}") || body_cy.include?("{{survey_link}}")
      errors.add(:survey, "must be present if {{survey_link}} placeholder is used") if survey.blank?
    end
  end
end
