class AddSurveyTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :survey_token, :string
    add_index :users, :survey_token, unique: true
  end
end
