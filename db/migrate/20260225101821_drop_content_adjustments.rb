class DropContentAdjustments < ActiveRecord::Migration[8.1]
  def change
    drop_table :content_adjustments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :reason, null: false
      t.integer :adjustment_type, null: false

      t.timestamps
    end
  end
end
