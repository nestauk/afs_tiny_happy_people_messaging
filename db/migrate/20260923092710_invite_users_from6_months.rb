class InviteUsersFrom6Months < ActiveRecord::Migration[8.1]
  def change
    User.where.not(restart_at: nil).find_each do |user|
      user.update(restart_at: user.child_birthday + 6.months)
    end
  end
end
