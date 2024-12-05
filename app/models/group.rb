class Group < ApplicationRecord
  has_many :contents, dependent: :destroy

  validates :name, presence: true

  def weekly_content
    contents.where(welcome_message: false)
  end
end
