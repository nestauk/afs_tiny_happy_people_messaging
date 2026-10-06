class RemoveSendAfterMessageCountFromSurveys < ActiveRecord::Migration[8.1]
  def change
    remove_column :surveys, :send_after_message_count, :integer
  end
end
