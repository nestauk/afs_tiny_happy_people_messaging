class AddThankYouToSurvey < ActiveRecord::Migration[8.1]
  def change
    add_column :surveys, :thank_you_title_en, :text
    add_column :surveys, :thank_you_body_en, :text
    add_column :surveys, :thank_you_title_cy, :text
    add_column :surveys, :thank_you_body_cy, :text
  end
end
