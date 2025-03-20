class AddCountryToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :local_authorities, :country, :string
  end
end
