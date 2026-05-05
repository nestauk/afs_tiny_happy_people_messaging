class AddIndexForeignKeyOnMessagesUserId < ActiveRecord::Migration[8.1]
  def change
    add_index :messages, :user_id
    add_foreign_key :messages, :users, column: :user_id
  end
end
