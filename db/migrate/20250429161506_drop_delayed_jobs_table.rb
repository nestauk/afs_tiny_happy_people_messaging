class DropDelayedJobsTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :delayed_jobs # rubocop:disable Rails/ReversibleMigration
  end
end
