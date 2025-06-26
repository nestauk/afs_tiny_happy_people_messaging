class ContentAgeGroup < ApplicationRecord
  validates :description, :min_months, :max_months, presence: true

  scope :return_two_groups, ->(direction, age) {
    where("min_months #{direction} ?", age).order(:min_months).limit(2)
  }
end
