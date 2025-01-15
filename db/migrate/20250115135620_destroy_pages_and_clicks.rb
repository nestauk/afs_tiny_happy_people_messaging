class DestroyPagesAndClicks < ActiveRecord::Migration[8.0]
  def change
    drop_table :clicks
    drop_table :pages
  end
end
