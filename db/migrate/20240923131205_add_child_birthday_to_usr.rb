class AddChildBirthdayToUsr < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :child_birthday, :date

    User.find_each do |user|
      user.update(child_birthday: Time.now - user.child_age.months)
    end

    remove_column :users, :child_age, :date
    change_column_null :users, :child_birthday, false
  end
end
