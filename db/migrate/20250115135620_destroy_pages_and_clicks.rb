class DestroyPagesAndClicks < ActiveRecord::Migration[8.0]
  def change
    drop_table :clicks # rubocop:disable Rails/ReversibleMigration
    drop_table :pages # rubocop:disable Rails/ReversibleMigration
  end
end
