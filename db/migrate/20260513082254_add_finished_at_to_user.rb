class AddFinishedAtToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :finished_content_at, :datetime
  end
end
