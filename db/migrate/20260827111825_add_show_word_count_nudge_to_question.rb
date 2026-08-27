class AddShowWordCountNudgeToQuestion < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :show_word_count_nudge, :boolean, default: false
  end
end
