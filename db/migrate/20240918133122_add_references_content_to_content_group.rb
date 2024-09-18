class AddReferencesContentToContentGroup < ActiveRecord::Migration[7.1]
  def change
    add_reference :contents, :content_group, index: true
    remove_column :contents, :lower_age, :integer
    remove_column :contents, :upper_age, :integer
    add_column :contents, :position, :integer, null: false
  end
end
