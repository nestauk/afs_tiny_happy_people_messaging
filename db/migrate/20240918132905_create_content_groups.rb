class CreateContentGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :content_groups do |t|
      t.string :name, null: false
      t.integer :age_in_months, null: false

      t.timestamps
    end
  end
end
