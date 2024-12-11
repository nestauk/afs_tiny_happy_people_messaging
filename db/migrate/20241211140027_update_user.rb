class UpdateUser < ActiveRecord::Migration[8.0]
  def up
    change_table :users do |t|
      t.remove :community_sign_up
      t.remove :family_support
      t.string :child_name
      t.boolean :diary_study, default: false
      t.integer :day_preference, default: 1, null: false
      t.integer :number_of_children
      t.string :children_ages
    end

    rename_column :users, :timing, :hour_preference
    change_column_null :users, :postcode, false
  end

  def down
    change_table :users do |t|
      t.boolean :community_sign_up
      t.boolean :family_support
      t.remove :child_name
      t.remove :diary_study, default: false
      t.remove :day_preference, default: 1, null: false
      t.remove :number_of_children
      t.remove :children_ages
    end

    rename_column :users, :hour_preference, :timing
  end
end
