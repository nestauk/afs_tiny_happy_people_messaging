class AddWelshTitleToSurvey < ActiveRecord::Migration[8.1]
  def change
    rename_column :surveys, :title, :title_en
    add_column :surveys, :title_cy, :string
  end
end
