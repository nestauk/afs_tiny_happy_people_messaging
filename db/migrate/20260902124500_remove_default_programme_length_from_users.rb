class RemoveDefaultProgrammeLengthFromUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_default :users, :programme_length, from: 52, to: nil
  end
end
