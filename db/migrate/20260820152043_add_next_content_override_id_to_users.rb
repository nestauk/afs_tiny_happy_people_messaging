class AddNextContentOverrideIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :next_content_override, foreign_key: {to_table: :contents}
  end
end
