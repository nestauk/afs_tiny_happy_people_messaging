class Message < ApplicationRecord
  belongs_to :user
  belongs_to :content, optional: true
  validates :body, presence: true, unless: :user_anonymised?

  scope :with_content, -> { where.not(content: nil) }
  scope :clicked, -> { with_content.where.not(clicked_at: nil) }
  scope :sent, -> { where.not(status: "received") }

  before_validation :set_token
  after_create :generate_reply, if: :received?

  def admin_status
    if clicked_at
      "Clicked"
    elsif status == "failed"
      "Failed"
    else
      status&.capitalize
    end
  end

  private

  def set_token
    return unless new_record? && token.nil? && link.present?

    loop do
      self.token = SecureRandom.alphanumeric(6)
      break unless Message.exists?(token: token)
    end
  end

  def received?
    status == "received"
  end

  def generate_reply
    ResponseMatcherJob.perform_later(self)
  end

  def user_anonymised?
    user.anonymised?
  end
end
