class RemoveContentAdjustmentReferencesFromAutoResponse < ActiveRecord::Migration[8.1]
  def change
    remove_column :auto_responses, :update_content_adjustment, :jsonb
    remove_column :auto_responses, :content_adjustment_conditions, :jsonb
  end
end
