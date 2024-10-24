class Group < ApplicationRecord
  has_many :contents, dependent: :destroy

  validates :name, :age_in_months, presence: true

  def welcome_message
    contents.find_by(welcome_message: true)
  end

  def weekly_content
    contents.where(welcome_message: false)
  end
end
