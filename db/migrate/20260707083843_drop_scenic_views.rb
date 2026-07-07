class DropScenicViews < ActiveRecord::Migration[8.1]
  def change
    drop_view :all_las_dashboards, materialized: true
    drop_view :la_specific_dashboards, materialized: true
  end
end
