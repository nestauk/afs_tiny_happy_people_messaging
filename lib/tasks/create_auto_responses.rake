namespace :create_auto_responses do
  desc "Create auto responses for triaging"
  task default: :environment do
    # Asked initially if content is appropriate, they text back no
    AutoResponse.find_by(trigger_phrase: "no").update!(
      response:	"We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if too easy, 2 if too hard, 3 if you want to give more context.",
      user_conditions: '{"asked_for_feedback": true, "contactable": true}',
      update_user: '{"asked_for_feedback": false}',
      content_adjustment_conditions: '{"needs_adjustment": null}',
      update_content_adjustment: '{"needs_adjustment": true}'
    )

    # They say content is too hard (1)
    AutoResponse.find_or_create_by!(
      trigger_phrase: "1",
      response: "Thanks for the feedback. Are you one of these groups? 1. Tiny elephant, 2. Tiny kangaroo, 3. I'm not sure",
      user_conditions: '{"contactable": true}',
      content_adjustment_conditions: '{"needs_adjustment": true}',
      update_content_adjustment: '{"direction": "up"}'
    )

    # They say content is too easy (2)
    AutoResponse.find_or_create_by!(
      trigger_phrase: "2",
      response: "Thanks for the feedback. Are you one of these groups? 1. Tiny elephant, 2. Tiny kangaroo, 3. I'm not sure",
      user_conditions: '{"contactable": true}',
      content_adjustment_conditions: '{"needs_adjustment": true}',
      update_content_adjustment: '{"direction": "down"}'
    )

    # They say they want to give more context (3)
    AutoResponse.find_or_create_by!(
      trigger_phrase: "3",
      response: "Thanks, a member of the team will be in touch to discuss your child's needs.",
      user_conditions: '{ "contactable": true}',
      content_adjustment_conditions: '{"needs_adjustment": true}',
      update_content_adjustment: '{"direction": "not_sure"}'
    )

    #  They specify the group that they belong to (1)
    AutoResponse.find_or_create_by!(
      trigger_phrase: "1",
      response: "Thanks, we've adjusted the content you'll receive. We'll check back in in a few weeks to make sure it's right.",
      user_conditions: '{"contactable": true}',
      content_adjustment_conditions: '{"needs_adjustment": true, "direction": "not_nil"}',
      update_content_adjustment: '{"needs_adjustment": false, "adjusted_at": "now"}'
    )

    #  They specify the group that they belong to (2)
    AutoResponse.find_or_create_by!(
      trigger_phrase: "2",
      response: "Thanks, we've adjusted the content you'll receive. We'll check back in in a few weeks to make sure it's right.",
      user_conditions: '{"contactable": true}',
      content_adjustment_conditions: '{"needs_adjustment": true, "direction": "not_nil"}',
      update_content_adjustment: '{"needs_adjustment": false, "adjusted_at": "now"}'
    )

    #  They're not sure which group they belong to (3)
    AutoResponse.find_or_create_by!(
      trigger_phrase: "3",
      response: "Thanks, a member of the team will be in touch to discuss your child's needs.",
      user_conditions: '{"contactable": true}',
      content_adjustment_conditions: '{"needs_adjustment": true, "direction": "not_sure"}'
    )
  end
end
