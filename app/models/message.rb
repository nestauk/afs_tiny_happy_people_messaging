class Message < ApplicationRecord
  belongs_to :user
  belongs_to :content, optional: true
  validates :body, presence: true

  scope :with_content, -> { where.not(content: nil) }
  scope :clicked, -> { with_content.where.not(clicked_at: nil) }

  before_validation :set_token
  after_create :generate_reply, if: :received?

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

  def received?
    status == "received"
  end

  def generate_reply
    incoming_message = body.downcase

    if STOP_WORDS.any? { |word| incoming_message.include?(word) }
      # Twilio handles sending a stop message, configured in the Twilio dashboard
      user.update(contactable: false)
    elsif START_WORDS.any? { |word| incoming_message.include?(word) }
      # Twilio handles sending a start message, configured in the Twilio dashboard
      user.update(contactable: true)
    elsif incoming_message.include? "pause"
      if user.update(contactable: false, restart_at: 4.weeks.from_now.noon)
        message = Message.create(user:, body: "Thanks, you've paused for 4 weeks.")
        SendCustomMessageJob.perform_later(message)
      end
    end
  end
end
