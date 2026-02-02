class CreateAhoyVisitsAndEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :ahoy_visits do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.string :visit_token
      t.string :visitor_token

      # the rest are recommended but optional
      # simply remove any you don't want

      # user
      t.references :user, type: :uuid

      # standard
      t.text :user_agent
      t.text :referrer
      t.string :referring_domain
      t.text :landing_page

      # technology
      t.string :browser
      t.string :os
      t.string :device_type

      t.datetime :started_at
    end

    add_index :ahoy_visits, :visit_token, unique: true
    add_index :ahoy_visits, [:visitor_token, :started_at]

    create_table :ahoy_events do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :visit
      t.references :user, type: :uuid

      t.string :name
      t.jsonb :properties
      t.datetime :time
    end

    add_index :ahoy_events, [:name, :time]
    add_index :ahoy_events, :properties, using: :gin, opclass: :jsonb_path_ops
  end
end
