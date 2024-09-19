class Message < ApplicationRecord
  belongs_to :user
  belongs_to :content, optional: true
  validates :body, presence: true

  scope :with_content, -> { where.not(content: nil) }
end
