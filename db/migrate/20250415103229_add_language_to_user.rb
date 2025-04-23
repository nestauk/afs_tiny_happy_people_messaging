class AddLanguageToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :language, :string, default: 'en', null: false
  end
end
