class Answer < ApplicationRecord
  belongs_to :question
  belongs_to :user

  def response=(value)
    super(Array(value).reject(&:empty?).join(", "))
  end

  validates :response, presence: true
end
