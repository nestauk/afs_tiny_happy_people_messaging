class AllowNullMessageToken < ActiveRecord::Migration[8.1]
  def change
    change_column_null :messages, :token, true
  end
end
