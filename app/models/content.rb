class Content < ApplicationRecord
  validates_presence_of :body, :upper_age, :lower_age
  has_many :messages

  default_scope { order(lower_age: :asc) }
end
