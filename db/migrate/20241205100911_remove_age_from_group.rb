class RemoveAgeFromGroup < ActiveRecord::Migration[7.2]
  def change
    add_column :contents, :age_in_months, :integer

    Content.find_each do |content|
      content.update(age_in_months: content.group.age_in_months)
    end

    remove_column :groups, :age_in_months, :integer
    change_column_null :contents, :age_in_months, false
  end
end
