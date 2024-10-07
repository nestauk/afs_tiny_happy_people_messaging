class AddRestartAtToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :restart_at, :datetime
  end
end
