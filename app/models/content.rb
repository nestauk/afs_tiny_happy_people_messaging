class Content < ApplicationRecord
  belongs_to :group
  positioned on: :group

  has_many :messages

  validates_presence_of :body
end
