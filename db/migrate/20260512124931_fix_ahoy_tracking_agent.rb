class FixAhoyTrackingAgent < ActiveRecord::Migration[8.1]
  def change
    remove_column :ahoy_visits, :user_agent, :string

    remove_column :ahoy_events, :user_id, :uuid
    remove_column :ahoy_visits, :user_id, :uuid

    add_column :ahoy_events, :user_id, :bigint
    add_index :ahoy_events, :user_id
    add_column :ahoy_visits, :user_id, :bigint
    add_index :ahoy_visits, :user_id
  end
end
