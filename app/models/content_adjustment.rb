class ContentAdjustment < ApplicationRecord
  belongs_to :user

  attr_accessor :content_age

  def needs_older_content?
    needs_adjustment? && direction == "up"
  end

  def needs_younger_content?
    needs_adjustment? && direction == "down"
  end

  def given_more_context?
    needs_adjustment? && direction.nil?
  end

  def messages
    user.messages.where("created_at > ?", created_at).order(:created_at)
  end
end
