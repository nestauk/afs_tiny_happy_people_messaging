require "net/http"
require "uri"

class Content < ApplicationRecord
  belongs_to :group
  positioned on: :group

  has_many :messages, dependent: :restrict_with_exception

  validates :body, :age_in_months, presence: true
  validate :valid_link?, if: -> { link.present? }

  scope :active, -> { where(archived_at: nil) }

  def archived?
    archived_at.present?
  end

  private

  def valid_link?
    uri = URI.parse(link)
    response = Net::HTTP.get_response(uri)

    if response.code != "200"
      errors.add(:link, "is not valid or does not return a 200 status code. Please check the link and try again.")
    end
  rescue
    errors.add(:link, "is not a valid URL. Please check the link and try again.")
  end
end
