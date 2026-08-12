class CreateAdminNotification < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_notifications do |t|
      t.date :sent_on, null: false

      t.timestamps
    end

    add_index :admin_notifications, :sent_on, unique: true
  end
end
