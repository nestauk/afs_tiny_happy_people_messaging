class AddClickedOnToMessage < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :clicked_on, :boolean, default: false
  end
end
