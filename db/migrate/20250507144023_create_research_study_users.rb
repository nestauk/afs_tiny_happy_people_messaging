class CreateResearchStudyUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :research_study_users do |t|
      t.string "postcode", null: false
      t.string "last_four_digits_phone_number", null: false
      t.timestamps
    end
  end
end
