class Group < ApplicationRecord
  has_many :contents

  validates :name, :age_in_months, presence: true
end
