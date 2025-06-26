class ContentAdjustment < ApplicationRecord
  belongs_to :user

  def needs_older_content?
    needs_adjustment? && direction == "up"
  end

  def needs_younger_content?
    needs_adjustment? && direction == "down"
  end
end
