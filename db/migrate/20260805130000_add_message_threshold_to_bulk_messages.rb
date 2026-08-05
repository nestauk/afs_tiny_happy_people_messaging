class AddMessageThresholdToBulkMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :bulk_messages, :message_threshold, :integer
  end
end
