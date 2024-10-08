class AddAdjustToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :adjust_amount, :integer, default: 0
  end
end
