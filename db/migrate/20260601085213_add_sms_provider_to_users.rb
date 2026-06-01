class AddSmsProviderToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :sms_provider, :string, default: "aws", null: false

    execute <<~SQL # rubocop:disable Rails/ReversibleMigration
      UPDATE users SET sms_provider = 'twilio'
      WHERE created_at < '2026-04-01'
    SQL
  end
end
