class AddLanguagePreferenceToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :new_language_preference, :string
  end
end
