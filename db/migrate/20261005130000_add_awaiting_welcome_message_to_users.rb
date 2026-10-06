class AddAwaitingWelcomeMessageToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :awaiting_welcome_message, :boolean, default: false, null: false
  end
end
