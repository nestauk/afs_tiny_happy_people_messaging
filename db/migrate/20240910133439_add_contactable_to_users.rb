class AddContactableToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :contactable, :boolean, default: true
  end
end
