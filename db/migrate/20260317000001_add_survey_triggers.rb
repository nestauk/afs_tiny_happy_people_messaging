class AddSurveyTriggers < ActiveRecord::Migration[8.1]
  def change
    add_column :surveys, :send_after_message_count, :integer
    add_column :surveys, :send_on_last_message, :boolean, default: false, null: false

    create_table :survey_sends do |t|
      t.references :user, null: false, foreign_key: true
      t.references :survey, null: false, foreign_key: true
      t.datetime :sent_at, null: false
      t.timestamps
    end

    add_index :survey_sends, [:user_id, :survey_id], unique: true

    remove_column :users, :sent_survey_at, :datetime
  end
end
