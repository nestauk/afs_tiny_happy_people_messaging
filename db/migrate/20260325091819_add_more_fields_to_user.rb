class AddMoreFieldsToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :language, :string, default: "en", null: false
    add_column :users, :referral_sources, :jsonb, default: []
    add_column :users, :education_status, :string

    User.find_each do |user|
      user.referral_sources = [user.referral_source] if user.referral_source.present?
      user.save(validate: false)
    end

    remove_column :users, :last_name, :string
    remove_column :users, :diary_study, :boolean
    remove_column :users, :email, :string
    remove_column :users, :incentive_receipt_method, :string
    remove_column :users, :new_language_preference, :string
    remove_column :users, :uuid, :uuid
    remove_column :users, :referral_source, :string
    change_column_null :users, :first_name, true
  end
end
