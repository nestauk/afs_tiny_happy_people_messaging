class RemoveSurveyIdFromQuestions < ActiveRecord::Migration[8.1]
  def change
    remove_reference :questions, :survey, foreign_key: true
  end
end
