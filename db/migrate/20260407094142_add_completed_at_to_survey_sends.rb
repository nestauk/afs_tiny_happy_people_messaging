class AddCompletedAtToSurveySends < ActiveRecord::Migration[8.1]
  def change
    add_column :survey_sends, :completed_at, :datetime
  end
end
