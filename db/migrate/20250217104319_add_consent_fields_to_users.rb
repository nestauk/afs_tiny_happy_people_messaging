class AddConsentFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :can_be_quoted_for_research, :boolean, default: false
    add_column :users, :can_be_contacted_for_research, :boolean, default: false
  end
end
