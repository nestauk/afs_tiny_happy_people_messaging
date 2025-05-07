class ResearchStudyUser < ApplicationRecord
  validates_presence_of :postcode, :last_four_digits_phone_number
  validates_uniqueness_of :postcode, scope: :last_four_digits_phone_number
end
