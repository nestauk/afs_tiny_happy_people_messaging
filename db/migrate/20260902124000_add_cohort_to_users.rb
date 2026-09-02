class AddCohortToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :cohort, :integer, default: 1, null: false

    execute <<~SQL # rubocop:disable Rails/ReversibleMigration
      UPDATE users SET cohort = 0
      WHERE created_at < '2026-05-01'
    SQL
  end
end
