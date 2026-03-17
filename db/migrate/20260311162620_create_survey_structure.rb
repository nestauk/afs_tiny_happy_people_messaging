class CreateSurveyStructure < ActiveRecord::Migration[8.1]
  def change
    create_table :surveys do |t|
      t.string :title, null: false
      t.timestamps
    end

    create_table :questions do |t|
      t.string :text, null: false
      t.integer :position, null: false
      t.string :question_type, null: false
      t.string :options, array: true, default: []
      t.references :survey, null: false, foreign_key: true
      t.timestamps
    end

    create_table :answers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.text :response, null: false
      t.timestamps
    end
  end
end
