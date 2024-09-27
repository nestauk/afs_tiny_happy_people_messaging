class MoveTokenToMessage < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :token, :string
    add_column :messages, :token, :string
    add_index :messages, :token, unique: true

    add_column :messages, :link, :string

    Message.find_each do |message|
      message.update(token: SecureRandom.alphanumeric(6))
    end

    change_column_null :messages, :token, false

    remove_column :messages, :clicked_on, :boolean
    add_column :messages, :clicked_at, :datetime
  end
end
