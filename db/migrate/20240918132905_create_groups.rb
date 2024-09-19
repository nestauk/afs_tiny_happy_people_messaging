class CreateGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.integer :age_in_months, null: false

      t.timestamps
    end
  end
end
