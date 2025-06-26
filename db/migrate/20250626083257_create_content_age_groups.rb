class CreateContentAgeGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :content_age_groups do |t|
      t.string :description, null: false
      t.integer :min_months, null: false
      t.integer :max_months, null: false
      t.timestamps
    end
  end
end
