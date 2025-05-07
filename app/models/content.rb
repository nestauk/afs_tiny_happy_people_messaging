class Content < ApplicationRecord
  belongs_to :group
  positioned on: :group

  has_many :messages, dependent: :restrict_with_exception

  validates_presence_of :body, :link, :age_in_months

  scope :active, -> { where(archived_at: nil) }

  WELCOME_MESSAGE = "Hi {{parent_name}}, welcome to our programme of weekly texts with fun activities for {{child_name}}'s development. Congrats on starting this amazing journey with your little one! To get started, why not save this number as 'Tiny Happy People' so you can easily see when it's us texting you?"
  WAITLIST_MESSAGE = "Hi {{parent_name}}! Thank you for signing up to the Tiny Happy People text messaging programme. We’re currently receiving a large volume of sign ups, and as a result we unfortunately will have to place you on a waiting list to receive this service. We expect that we will be able to provide the service for you starting in September provided your child is still under 24 months. Please respond STOP if you would like to opt out, otherwise we will send your first text messages in September. We hope that you will join us in the autumn!"

  def archived?
    archived_at.present?
  end
end
