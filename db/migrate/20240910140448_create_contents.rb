class CreateContents < ActiveRecord::Migration[7.1]
  def change
    create_table :contents do |t|
      t.text :body
      t.integer :lower_age
      t.integer :upper_age
      t.timestamps
    end

    change_table :messages do |t|
      t.references :content, foreign_key: true
      t.string :message_sid
      t.string :status
      t.datetime :sent_at
    end
  end
end
