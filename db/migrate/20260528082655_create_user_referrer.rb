class CreateUserReferrer < ActiveRecord::Migration[8.1]
  def change
    create_table :user_referrers do |t|
      t.string :utm_source
      t.string :utm_medium
      t.string :utm_campaign
      t.string :utm_term
      t.string :utm_content
      t.string :gclid
      t.timestamps
    end
  end
end
