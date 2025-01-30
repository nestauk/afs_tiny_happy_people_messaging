class UpdateAutoResponse < ActiveRecord::Migration[8.0]
  def change
    AutoResponse.find_by(trigger_phrase: "no", response: "We can adjust the activities we send. Respond 1 if they are too simple or 2 if they are too advanced.").update(response: "We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if your child is not yet saying words, 2 if they are saying single words, 3 if they are saying whole sentences.")
  end
end
