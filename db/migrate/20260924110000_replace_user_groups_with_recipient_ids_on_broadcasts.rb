class ReplaceUserGroupsWithRecipientIdsOnBroadcasts < ActiveRecord::Migration[8.1]
  def change
    remove_column :broadcasts, :user_groups, :string, array: true, default: [], null: false
    remove_column :broadcasts, :message_threshold, :integer
    add_column :broadcasts, :recipient_ids, :integer, array: true, default: [], null: false
  end
end
