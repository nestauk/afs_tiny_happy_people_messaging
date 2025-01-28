class CreateAutoResponses < ActiveRecord::Migration[8.0]
  class AutoResponse < ApplicationRecord; end

  def change
    add_column :users, :asked_for_feedback, :boolean, default: false

    create_table :auto_responses do |t|
      t.string :trigger_phrase, null: false
      t.string :response, null: false
      t.jsonb :update_user, default: {}
      t.jsonb :conditions, default: {}
      t.timestamps
    end

    AutoResponse.create(trigger_phrase: "pause", response: "Thanks, you've paused for 4 weeks.", update_user: '{"contactable": false, "restart_at": "4.weeks.from_now.noon"}')
    AutoResponse.create(trigger_phrase: "yes", response: "That's great to hear, thanks for letting us know!", conditions: '{"asked_for_feedback": true}', update_user: '{"asked_for_feedback": false}')
    AutoResponse.create(trigger_phrase: "no", response: "We can adjust the activities we send. Respond 1 if they are too simple or 2 if they are too advanced.", conditions: '{"asked_for_feedback": true}', update_user: '{"asked_for_feedback": false}')
  end
end
