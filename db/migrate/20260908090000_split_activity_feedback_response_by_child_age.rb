class SplitActivityFeedbackResponseByChildAge < ActiveRecord::Migration[8.1]
  ORIGINAL_RESPONSE = "We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if your child is not yet saying words, 2 if they are saying single words, 3 if they are saying whole sentences."

  AGE_BRACKETS = [[9, 11], [12, 15], [16, 18], [19, 21], [22, 24], [25, nil]].freeze

  def change
    reversible do |dir|
      dir.up do
        AutoResponse.where(trigger_phrase: "no", response: ORIGINAL_RESPONSE).destroy_all

        AGE_BRACKETS.each do |min, max|
          label = max ? "#{min} to #{max} months" : "#{min}+ months"

          AutoResponse.create!(
            trigger_phrase: "no",
            description: "Activity suitability feedback - #{label}",
            response: ORIGINAL_RESPONSE,
            user_conditions: {asked_for_feedback: true, child_age_in_months_between: [min, max]}.to_json,
            update_user: {asked_for_feedback: false}.to_json,
          )
        end
      end

      dir.down do
        AutoResponse.where(trigger_phrase: "no", response: ORIGINAL_RESPONSE).destroy_all

        AutoResponse.create!(
          trigger_phrase: "no",
          response: ORIGINAL_RESPONSE,
          user_conditions: {asked_for_feedback: true}.to_json,
          update_user: {asked_for_feedback: false}.to_json,
        )
      end
    end
  end
end
