class AddLinkToContent < ActiveRecord::Migration[7.1]
  def change
    add_column :contents, :link, :string
  end
end
