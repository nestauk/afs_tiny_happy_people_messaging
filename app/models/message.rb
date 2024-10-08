class Message < ApplicationRecord
  belongs_to :user
  belongs_to :content, optional: true
  validates :body, presence: true

  scope :with_content, -> { where.not(content: nil) }

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
      user.update(contactable: false, restart_at: 2.weeks.from_now.noon)
      message = Message.create(user:, body: "Thanks, you've paused for 2 weeks. To change how long for text: 1. 1 month - text '1MONTH' 2. 3 months - text '3MONTHS'")
      SendCustomMessageJob.perform_later(message)
    elsif incoming_message.include?("2") && incoming_message.include?("week")
      user.update(restart_at: 2.weeks.from_now.noon)
    elsif incoming_message.include?("1") && incoming_message.include?("month")
      user.update(restart_at: 1.month.from_now.noon)
    elsif incoming_message.include?("3") && incoming_message.include?("month")
      user.update(restart_at: 3.months.from_now.noon)
    end
  end
end
