class CreateContentAdjustments < ActiveRecord::Migration[8.0]
  def change
    create_table :content_adjustments do |t|
      t.references :user, null: false, foreign_key: true
      t.boolean :needs_adjustment
      t.string :direction
      t.datetime :adjusted_at
      t.timestamps
    end
  end
end
