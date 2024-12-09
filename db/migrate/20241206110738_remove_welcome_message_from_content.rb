class RemoveWelcomeMessageFromContent < ActiveRecord::Migration[8.0]
  def change
    remove_column :contents, :welcome_message, :boolean
  end
end
