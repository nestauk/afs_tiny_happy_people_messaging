class AddTokenToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :token, :string

    User.find_each do |user|
      user.update(token: SecureRandom.hex(10))
    end

    change_column_null :users, :token, false
  end
end
