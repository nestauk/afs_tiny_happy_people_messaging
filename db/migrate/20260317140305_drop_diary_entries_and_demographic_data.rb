class DropDiaryEntriesAndDemographicData < ActiveRecord::Migration[8.1]
  def change
    drop_table :diary_entries do |t|
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

    drop_table :demographic_data do |t|
      t.references :user, null: false, foreign_key: true
      t.string :gender
      t.integer :age
      t.integer :number_of_children
      t.string :children_ages
      t.string :country
      t.string :ethnicity
      t.string :education
      t.string :marital_status
      t.string :employment_status
      t.string :household_income
      t.boolean :receiving_credit
      t.timestamps
    end
  end
end
