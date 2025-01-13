class CreateAllLasDashboards < ActiveRecord::Migration[8.0]
  def change
    create_view :all_las_dashboards, materialized: true
  end
end
