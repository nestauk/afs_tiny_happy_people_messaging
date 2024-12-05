class Content < ApplicationRecord
  belongs_to :group
  positioned on: :group

  has_many :messages, dependent: :nullify

  validates_presence_of :body, :link, :age_in_months
end
