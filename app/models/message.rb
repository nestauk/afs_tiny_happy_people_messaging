class Message < ApplicationRecord
  scope :with_content, -> { where.not(content: nil) }

  belongs_to :user
  belongs_to :content, optional: true

  validates :body, presence: true
  validates :token, presence: true, uniqueness: true

  before_validation :set_token

  def admin_status
    if status == "delivered"
      clicked_on ? "Clicked" : "Delivered"
    else
      status&.capitalize
    end
  end

  protected

  def generate_token
    SecureRandom.alphanumeric(6)
  end

  def set_token
    self.token = generate_token if new_record? && token.nil?
  end
end
