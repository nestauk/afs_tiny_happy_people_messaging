class AddMarkedAsSeenAtToMessage < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :marked_as_seen_at, :datetime
  end
end
