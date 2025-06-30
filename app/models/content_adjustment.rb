class ContentAdjustment < ApplicationRecord
  belongs_to :user

  scope :complete, -> {
    where.not(adjusted_at: nil).order("created_at DESC")
  }
  scope :incomplete, -> {
    where("adjusted_at IS NULL AND needs_adjustment = 'true' AND (direction != 'not_sure' OR direction IS NULL)")
  }

  def needs_older_content?
    needs_adjustment? && direction == "up"
  end

  def needs_younger_content?
    needs_adjustment? && direction == "down"
  end
end
