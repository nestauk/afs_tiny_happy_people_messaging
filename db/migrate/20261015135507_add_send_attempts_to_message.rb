class AddSendAttemptsToMessage < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :send_attempts, :integer, default: 0, null: false
  end
end
