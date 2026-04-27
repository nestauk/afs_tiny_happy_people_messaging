class AddProgrammeLengthToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :programme_length, :integer
    change_column_default :users, :programme_length, from: nil, to: 52
  end
end
