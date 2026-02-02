class AddUniqueIndexToUserPostcodeAndPhoneNumber < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :phone_number, unique: true
    add_index :research_study_users, [:last_four_digits_phone_number, :postcode], unique: true
  end
end
