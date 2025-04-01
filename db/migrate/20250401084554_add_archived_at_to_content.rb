class AddArchivedAtToContent < ActiveRecord::Migration[8.0]
  def change
    add_column :contents, :archived_at, :datetime
  end
end
