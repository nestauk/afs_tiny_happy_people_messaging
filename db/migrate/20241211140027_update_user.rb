class UpdateUser < ActiveRecord::Migration[8.0]
  def up
    change_table :users do |t|
      t.remove :community_sign_up
      t.remove :family_support
      t.string :child_name
      t.boolean :diary_study, default: false
      t.integer :day_preference, default: 1, null: false
      t.string :referral_source
      t.string :diary_study_contact_method
      t.string :email
      t.uuid :uuid
    end

    User.where(postcode: nil).update_all(postcode: "N/A")

    rename_column :users, :timing, :hour_preference
    change_column_null :users, :postcode, false
    add_index :users, :uuid, unique: true
  end

  def down
    change_table :users do |t|
      t.boolean :community_sign_up
      t.boolean :family_support
      t.remove :child_name
      t.remove :diary_study, default: false
      t.remove :day_preference, default: 1, null: false
      t.remove :referral_source
      t.remove :diary_study_contact_method
      t.remove :email
      t.remove :uuid
    end

    rename_column :users, :hour_preference, :timing
  end
end
