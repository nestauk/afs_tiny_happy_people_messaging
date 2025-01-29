class Message < ApplicationRecord
  belongs_to :user
  belongs_to :content, optional: true
  validates :body, presence: true

  scope :with_content, -> { where.not(content: nil) }
  scope :clicked, -> { with_content.where.not(clicked_at: nil) }
  scope :sent, -> { where.not(status: "received") }

  before_validation :set_token
  after_create :generate_reply, if: :received?

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
    ResponseMatcherService.new(self).match_response
  end
end
