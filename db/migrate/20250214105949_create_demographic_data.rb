class CreateDemographicData < ActiveRecord::Migration[8.0]
  def change
    create_table :demographic_data do |t|
      t.references :user, null: false, foreign_key: true
      t.string :gender
      t.integer :age
      t.integer :number_of_children
      t.string :children_ages
      t.string :country
      t.string :ethnicity
      t.string :education
      t.string :marital_status
      t.string :employment_status
      t.string :household_income
      t.boolean :receiving_credit
      t.timestamps
    end
  end
end
