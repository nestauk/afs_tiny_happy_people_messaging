class RenameBulkMessagesToBroadcasts < ActiveRecord::Migration[8.1]
  def change
    rename_table :bulk_messages, :broadcasts
    rename_column :messages, :bulk_message_id, :broadcast_id
  end
end
