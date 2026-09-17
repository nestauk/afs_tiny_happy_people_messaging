class AddLanguageToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :language, :string
  end
end
