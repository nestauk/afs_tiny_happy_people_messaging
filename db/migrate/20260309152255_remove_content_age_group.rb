class RemoveContentAgeGroup < ActiveRecord::Migration[8.1]
  def change
    drop_table :content_age_groups do |t|
      t.string :description
      t.integer :min_months
      t.integer :max_months
      t.timestamps
    end
  end
end
