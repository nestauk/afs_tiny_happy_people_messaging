class AddLocalAuthorityToAdmin < ActiveRecord::Migration[8.0]
  def change
    add_column :admins, :role, :string, default: "admin", null: false
  end
end
