class Content < ApplicationRecord
  validates_presence_of :body, :upper_age, :lower_age
end
