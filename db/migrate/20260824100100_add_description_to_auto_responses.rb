class AddDescriptionToAutoResponses < ActiveRecord::Migration[8.1]
  def change
    add_column :auto_responses, :description, :string
  end
end
