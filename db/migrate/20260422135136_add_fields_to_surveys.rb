class AddFieldsToSurveys < ActiveRecord::Migration[8.1]
  def change
    add_column :surveys, :intro_en, :text
    add_column :surveys, :intro_cy, :text

    add_column :questions, :hint_en, :string
    add_column :questions, :hint_cy, :string

    create_table :survey_sections do |t|
      t.string :title_en
      t.string :title_cy
      t.integer :position
      t.references :survey, null: false, foreign_key: true

      t.timestamps
    end

    add_reference :questions, :survey_section, foreign_key: true
  end
end
