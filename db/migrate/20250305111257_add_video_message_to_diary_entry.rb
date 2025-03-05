class AddVideoMessageToDiaryEntry < ActiveRecord::Migration[8.0]
  def change
    add_column :diary_entries, :video_message, :string
  end
end
