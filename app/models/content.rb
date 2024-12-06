class Content < ApplicationRecord
  belongs_to :group
  positioned on: :group

  has_many :messages, dependent: :nullify

  validates_presence_of :body, :link, :age_in_months

  WELCOME_MESSAGE = "Hi [Parent], welcome to our programme of weekly texts with fun activities for [Child]’s development. Congrats on starting this amazing journey with your little one!"
end
