class AddLastContentToUser < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :last_content, foreign_key: {to_table: :contents}
  end
end
