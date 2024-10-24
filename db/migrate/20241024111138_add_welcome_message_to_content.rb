class AddWelcomeMessageToContent < ActiveRecord::Migration[7.1]
  def change
    add_column :contents, :welcome_message, :boolean, default: false
  end
end
