class AddConsentToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :consent_given_at, :datetime
  end
end
