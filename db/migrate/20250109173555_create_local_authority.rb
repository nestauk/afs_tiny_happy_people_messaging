class CreateLocalAuthority < ActiveRecord::Migration[8.0]
  def change
    create_table :local_authorities do |t|
      t.string :name, null: false
      t.timestamps
    end

    add_reference :users, :local_authority, foreign_key: {to_table: :local_authorities}
  end
end
