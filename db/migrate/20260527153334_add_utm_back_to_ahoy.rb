class AddUtmBackToAhoy < ActiveRecord::Migration[8.1]
  def change
    add_column :ahoy_visits, :utm_source, :string
    add_column :ahoy_visits, :utm_medium, :string
    add_column :ahoy_visits, :utm_campaign, :string
    add_column :ahoy_visits, :utm_term, :string
    add_column :ahoy_visits, :utm_content, :string
  end
end
