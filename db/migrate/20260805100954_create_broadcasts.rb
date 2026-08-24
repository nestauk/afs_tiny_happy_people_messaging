class CreateBroadcasts < ActiveRecord::Migration[8.1]
  def change
    create_table :broadcasts do |t|
      t.text :body_en
      t.text :body_cy
      t.references :admin, null: false, foreign_key: true
      t.references :survey, foreign_key: true
      t.string :user_groups, array: true, default: [], null: false
      t.integer :message_threshold
      t.datetime :sent_at
      t.timestamps
    end

    add_reference :messages, :broadcast, foreign_key: true, index: true
  end
end
