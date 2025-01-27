class UpdateAllLasDashboardsToVersion2 < ActiveRecord::Migration[8.0]
  def change
    update_view :all_las_dashboards, version: 2, revert_to_version: 1, materialized: true
  end
end
