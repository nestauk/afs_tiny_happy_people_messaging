class AddUpOptionDownOptionToContentAdjustment < ActiveRecord::Migration[8.0]
  def change
    add_column :content_adjustments, :number_up_options, :integer
    add_column :content_adjustments, :number_down_options, :integer

    ContentAdjustment.find_each do |adjustment|
      adjustment.update(
        number_up_options: adjustment.number_options,
        number_down_options: adjustment.number_options
      )
    end

    remove_column :content_adjustments, :number_options
  end
end
