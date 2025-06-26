class AddUpdateContentAdjustmentToAutoResponse < ActiveRecord::Migration[8.0]
  def change
    add_column :auto_responses, :update_content_adjustment, :jsonb, default: "{}"
    add_column :auto_responses, :content_adjustment_conditions, :jsonb, default: "{}"
    rename_column :auto_responses, :conditions, :user_conditions
  end
end
