class CheckAdjustmentJob < ApplicationJob
  queue_as :default

  def perform
    # Check for adjustments that need to be made
    adjustments = Adjustment.where(checked: false)

    adjustments.each do |adjustment|
      # Perform the adjustment logic here
      adjustment.perform_adjustment

      # Mark the adjustment as checked
      adjustment.update(checked: true)
    end
  end
end
