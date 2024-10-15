class CreateClickTable < ActiveRecord::Migration[7.1]
  def change
    create_table :pages do |t|
      t.string :name
      t.timestamps
    end

    create_table :clicks do |t|
      t.references :page, null: false, foreign_key: true
      t.timestamps
    end
  end
end
