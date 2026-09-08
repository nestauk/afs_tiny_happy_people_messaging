class InstallSkadi < ActiveRecord::Migration[8.1]
  def change
    create_table :skadi_visits do |t|
      # A random uuid identifying the visit. This will be sent to the front-end to allow updates to the visit javascript flag without exposing details about the site analytics to the user.
      t.uuid :visit_token, null: false

      # A token identifying the user. This will either be a token generated from an anonymity set based on the user's IP and User Agent, or it will be sourced from a cookie.
      t.uuid :tracking_token

      # The ID of a logged in user. The FK is intentionally absent in case the host app doesn't have a users table.
      t.references :user, type: :bigint, index: false

      t.text :referrer
      t.text :landing_page

      # Standard UTM parameters
      t.text :utm_source
      t.text :utm_medium
      t.text :utm_term
      t.text :utm_content
      t.text :utm_campaign

      # Whether the visit has been verified by the front-end
      t.boolean :verified, null: false, default: false

      t.boolean :cookies_enabled, null: false, default: false

      t.timestamps
    end

    add_index :skadi_visits, :visit_token, unique: true
    add_index :skadi_visits, :created_at
    add_index :skadi_visits, [:tracking_token, :created_at]
    add_index :skadi_visits, [:user_id, :created_at]

    create_table :skadi_views do |t|
      # Intentionally left nullable as not all requests will have a visit in the case a user has requested no tracking.
      t.references :visit, foreign_key: {to_table: :skadi_visits, on_delete: :cascade}, index: false

      # A random uuid identifying the view. This will be sent to the front-end to allow updates to the view metrics without exposing details about the site analytics to the user.
      t.uuid :view_token, null: false

      t.string :controller, null: false
      t.string :action, null: false
      t.string :verb, null: false
      t.text :path, null: false
      t.jsonb :query_params

      # The page the user clicked on when leaving the page
      t.text :exit_page

      # Whether the view has been verified by the front-end
      t.boolean :verified, null: false, default: false

      # Version of the page presented to the user (e.g. branch A/B)
      t.string :version

      t.timestamps
    end

    add_index :skadi_views, :view_token, unique: true
    add_index :skadi_views, :created_at
    add_index :skadi_views, [:path, :created_at]
    add_index :skadi_views, [:visit_id, :created_at]

    create_table :skadi_events do |t|
      # Intentionally left nullable as not all requests will have a visit in the case a user has requested no tracking.
      t.references :visit, foreign_key: {to_table: :skadi_visits, on_delete: :cascade}, index: false

      # Intentionally left nullable as not all requests will have a visit in the case a user has requested no tracking.
      t.references :view, foreign_key: {to_table: :skadi_views, on_delete: :cascade}, index: false

      t.string :name, null: false
      t.jsonb :properties

      t.datetime :created_at, null: false
    end

    add_index :skadi_events, :created_at
    add_index :skadi_events, [:name, :created_at]
    add_index :skadi_events, [:view_id, :created_at]
    add_index :skadi_events, [:visit_id, :created_at]
    add_index :skadi_events, :properties, using: :gin, opclass: :jsonb_path_ops

    # Store demographic data separately so that it cannot be used to identify users
    # E.g. screen size, language, timezone, pointer type (mouse, touch), can-hover, prefers reduced motion, prefers contrast, forced colours, prefers dark mode
    create_table :skadi_demographics do |t|
      t.string :uri, null: false
      t.string :name, null: false
      t.string :value, null: false
      t.date :recorded_on, null: false
      t.integer :count, null: false, default: 0
      t.timestamps
    end

    add_index :skadi_demographics, [:uri, :name, :value, :recorded_on], unique: true

    create_table :skadi_dashboards do |t|
      t.string :name, null: false
      t.text :description
      t.jsonb :configuration, null: false

      t.timestamps
    end
  end
end
