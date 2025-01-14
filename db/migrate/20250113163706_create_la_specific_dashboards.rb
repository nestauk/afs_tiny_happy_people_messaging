class CreateLaSpecificDashboards < ActiveRecord::Migration[8.0]
  def change
    create_view :la_specific_dashboards, materialized: true
  end
end
