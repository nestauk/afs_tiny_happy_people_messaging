class AddFieldsToUser < ActiveRecord::Migration[7.1]
  def change
    change_table(:users, bulk: true) do |t|
      t.string :postcode
      t.string :timing
      t.boolean :community_sign_up
      t.boolean :family_support
      t.datetime :terms_agreed_at
    end

    User.find_each do |user|
      user.update(terms_agreed_at: user.created_at)
    end

    change_column_null :users, :terms_agreed_at, false
  end
end
