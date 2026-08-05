class AddUserGroupsToBulkMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :bulk_messages, :user_groups, :string, array: true, default: [], null: false
  end
end
