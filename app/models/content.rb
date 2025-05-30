class Content < ApplicationRecord
  belongs_to :group
  positioned on: :group

  has_many :messages, dependent: :restrict_with_exception

  validates_presence_of :body, :link, :age_in_months

  scope :active, -> { where(archived_at: nil) }

  WELCOME_MESSAGE = "Hi {{parent_name}}, welcome to our programme of weekly texts with fun activities for {{child_name}}'s development. Congrats on starting this amazing journey with your little one! To get started, why not save this number as 'Tiny Happy People' so you can easily see when it's us texting you?"

  def archived?
    archived_at.present?
  end
end
