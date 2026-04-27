class RemoveSendOnLastMessageFromSurvey < ActiveRecord::Migration[8.1]
  def change
    remove_column :surveys, :send_on_last_message, :boolean, default: false
  end
end
