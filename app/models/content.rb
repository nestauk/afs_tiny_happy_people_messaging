class Content < ApplicationRecord
  belongs_to :content_group
  has_many :messages

  validates_presence_of :body
end
