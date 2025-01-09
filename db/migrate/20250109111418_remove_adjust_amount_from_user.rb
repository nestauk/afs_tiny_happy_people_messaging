class RemoveAdjustAmountFromUser < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :adjust_amount, :integer
  end
end
