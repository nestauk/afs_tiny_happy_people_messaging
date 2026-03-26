class AddGroupReferenceToUser < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :group, null: true, foreign_key: true

    User.find_each do |user|
      group = Group.order(:created_at).first
      user.group = group
      user.save!(validate: false)
    end

    change_column_null :users, :group_id, false
  end
end
