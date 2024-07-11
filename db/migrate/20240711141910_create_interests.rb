class CreateInterests < ActiveRecord::Migration[7.1]
  def change
    create_table :interests do |t|
      t.references :user, foreign_key: true
      t.string :title, null: false
      t.timestamps
    end
  end
end
