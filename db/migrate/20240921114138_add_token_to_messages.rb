class AddTokenToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :token, :string, null: false
    add_index :messages, :token, unique: true
    remove_column :messages, :clicked_on, :boolean
    add_column :messages, :clicked_at, :datetime
  end
end
