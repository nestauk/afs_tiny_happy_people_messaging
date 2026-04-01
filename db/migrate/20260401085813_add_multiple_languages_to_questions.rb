class AddMultipleLanguagesToQuestions < ActiveRecord::Migration[8.1]
  def change
    rename_column :questions, :text, :text_en
    add_column :questions, :text_cy, :string, null: false, default: ""

    rename_column :questions, :options, :options_en
    add_column :questions, :options_cy, :string, array: true, default: []
  end
end
