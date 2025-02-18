class AddIncentiveReceiptToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :incentive_receipt_method, :string
    remove_column :users, :diary_study_contact_method, :string
  end
end
