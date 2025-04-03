class AddSentSurveyAtToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :sent_survey_at, :datetime
  end
end
