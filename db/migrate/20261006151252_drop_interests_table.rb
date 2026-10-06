class DropInterestsTable < ActiveRecord::Migration[8.1]
  def change
    drop_table :interests do |t|
      t.references :user, foreign_key: true
      t.string :title, null: false
      t.timestamps
    end
  end
end
