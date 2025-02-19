class CreateDiaryEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :diary_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :days, array: true, default: []
      t.jsonb :timings, array: true, default: []
      t.integer :total_time
      t.boolean :did_previous_week_activity, default: nil
      t.boolean :first_week, default: nil
      t.text :activities_from_previous_weeks
      t.jsonb :feedback, array: true, default: []
      t.text :feedback_reason
      t.text :reason_for_not_doing_activity
      t.text :enjoyed_most
      t.text :enjoyed_least
      t.text :changes_to_make
      t.datetime :completed_at
      t.timestamps
    end
  end
end
