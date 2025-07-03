class ContentAgeGroup < ApplicationRecord
  validates :description, :min_months, :max_months, presence: true

  scope :return_two_groups, ->(direction, age) {
    if direction == "<"
      where("max_months #{direction} ?", age).order(:max_months).limit(2)
    elsif direction == ">"
      where("min_months #{direction} ?", age).order(:min_months).limit(2)
    end
  }
end
