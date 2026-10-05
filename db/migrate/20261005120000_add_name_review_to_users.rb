class AddNameReviewToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :needs_name_review, :boolean, default: false, null: false
    add_column :users, :name_reviewed_at, :datetime
  end
end
