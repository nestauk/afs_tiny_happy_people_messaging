class AddSentBilingualTextToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :sent_bilingual_text_at, :datetime

    User.find_each do |user|
      user.sent_bilingual_text_at = Time.zone.now
      user.save!(validate: false)
    end
  end
end
