class AddExperimentNameToGroups < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :experiment_name, :string
  end
end
