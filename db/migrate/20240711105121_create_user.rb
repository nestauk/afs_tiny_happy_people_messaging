class CreateUser < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :phone_number, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.integer :child_age, null: false
      t.jsonb :interests, array: true, default: []
      t.timestamps
    end
  end
end
