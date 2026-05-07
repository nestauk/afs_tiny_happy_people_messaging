class RemoveUniqueIndexFromSurveySends < ActiveRecord::Migration[8.1]
  def change
    remove_index :survey_sends, column: [:user_id, :survey_id], unique: true
    add_index :survey_sends, [:user_id, :survey_id]
  end
end
