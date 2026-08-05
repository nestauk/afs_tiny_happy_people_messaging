class CreateBulkMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :bulk_messages do |t|
      t.text :body_en
      t.text :body_cy
      t.references :admin, null: false, foreign_key: true
      t.references :survey, foreign_key: true
      t.datetime :sent_at
      t.timestamps
    end

    add_reference :messages, :bulk_message, foreign_key: true, index: true
  end
end
