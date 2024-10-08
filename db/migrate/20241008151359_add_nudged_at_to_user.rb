class AddNudgedAtToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :nudged_at, :datetime
  end
end
