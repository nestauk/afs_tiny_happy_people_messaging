class RemoveEducationStatusFromUser < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :education_status, :string
  end
end
