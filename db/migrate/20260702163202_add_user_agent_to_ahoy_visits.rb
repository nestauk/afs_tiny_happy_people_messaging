class AddUserAgentToAhoyVisits < ActiveRecord::Migration[8.1]
  def change
    add_column :ahoy_visits, :user_agent, :text
  end
end
