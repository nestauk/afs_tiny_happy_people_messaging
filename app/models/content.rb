require "net/http"
require "uri"

class Content < ApplicationRecord
  belongs_to :group
  positioned on: :group

  has_many :messages, dependent: :restrict_with_exception

  validates :body, :age_in_months, presence: true
  validates :link, format: {with: URI::DEFAULT_PARSER.make_regexp(%w[http https])}, allow_blank: true

  scope :active, -> { where(archived_at: nil) }

  after_create :check_link_status

  def archived?
    archived_at.present?
  end

  private

  def check_link_status
    CheckBbcLinksJob.perform_later if link.present?
  end
end
