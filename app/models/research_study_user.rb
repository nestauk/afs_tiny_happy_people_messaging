class ResearchStudyUser < ApplicationRecord
  validates :postcode, :last_four_digits_phone_number, presence: true
  validates :postcode, uniqueness: {scope: :last_four_digits_phone_number}
end
