class User < ApplicationRecord
  scope :contactable, -> { where(contactable: true) }

  has_many :interests
  has_many :messages, dependent: :destroy
  has_many :contents, through: :messages
  has_many :field_test_memberships, class_name: 'FieldTest::Membership', as: :participant

  validates :phone_number, :first_name, :last_name, :child_age, presence: true
  validates_uniqueness_of :phone_number
  phony_normalize :phone_number, default_country_code: 'UK'

  accepts_nested_attributes_for :interests

  scope :contactable, -> { where(contactable: true) }

  before_create :generate_token

  def generate_token
    self.token = SecureRandom.hex(10)
  end

  def child_age_in_months_today
    (Time.now.year * 12 + Time.now.month) - (child_birthday.year * 12 + child_birthday.month)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def next_content
    experiment = FieldTest::Experiment.find(:shorter_msgs)

    group = if experiment.variant(self) == 'treatment'
              # TODO: risk of no group being found
              Group.find_by(age_in_months: child_age_in_months_today, experiment_name: 'shorter_msgs')
            else
              Group.find_by(age_in_months: child_age_in_months_today, experiment_name: nil)
            end

    # find lowest ranked content minus any they have already seen
    (group.contents - contents).min_by(&:position)
  end
end
