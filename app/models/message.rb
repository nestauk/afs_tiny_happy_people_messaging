class Message < ApplicationRecord
  belongs_to :user
  belongs_to :content, optional: true
  validates :body, presence: true

  scope :with_content, -> { where.not(content: nil) }

  before_validation :set_token

  STOP_WORDS = %w[stop stopall unsubscribe cancel end quit].freeze
  START_WORDS = %w[start yes unstop].freeze

  def admin_status
    if status == "delivered"
      clicked_at ? "Clicked" : "Delivered"
    else
      status&.capitalize
    end
  end

  def generate_token
    self.token = SecureRandom.alphanumeric(6)
  end

  private

  def set_token
    return unless new_record? && token.nil?

    token = generate_token

    while Message.exists?(token:)
      generate_token
    end
  end
end
