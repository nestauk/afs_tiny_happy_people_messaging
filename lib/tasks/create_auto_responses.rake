namespace :create_auto_responses do
  desc "Create auto responses for triaging"
  task create: :environment do
    # Asked initially if content is appropriate, they text back no
    AutoResponse.find_by(trigger_phrase: "no").update!(
      response:	"We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if too easy, 2 if too hard, or reply with your message if you want to give more context.",
      user_conditions: '{"asked_for_feedback": true, "contactable": true}',
      update_user: '{"asked_for_feedback": false}',
      content_adjustment_conditions: '{"needs_adjustment": null}',
      update_content_adjustment: '{"needs_adjustment": true, "number_up_options": "number_up_options", "number_down_options": "number_down_options"}'
    )

    # There aren't any adjustments available
    AutoResponse.find_or_create_by!(
      trigger_phrase: "1",
      response: "Thanks, a member of the team will be in touch to discuss your child's needs.",
      user_conditions: '{"contactable": true}',
      update_user: '{"asked_for_feedback": false}',
      update_content_adjustment: '{"direction": "not_sure"}',
      content_adjustment_conditions: '{"needs_adjustment": true, "number_up_options": 0}'
    )
    AutoResponse.find_or_create_by!(
      trigger_phrase: "2",
      response: "Thanks, a member of the team will be in touch to discuss your child's needs.",
      user_conditions: '{"contactable": true}',
      update_user: '{"asked_for_feedback": false}',
      update_content_adjustment: '{"direction": "not_sure"}',
      content_adjustment_conditions: '{"needs_adjustment": true, "number_down_options": 0}'
    )

    # There are adjustments available
    # They say content is too hard (1)
    AutoResponse.find_or_create_by!(
      trigger_phrase: "1",
      response: "Every baby develops at their own pace, and we’ve designed our content to match a range of developmental stages. To adjust, pick the animal that sounds most like your little one right now.\n{{content_age_groups}}",
      user_conditions: '{"contactable": true}',
      update_user: "{}",
      content_adjustment_conditions: '{"needs_adjustment": true, "direction": null, "number_up_options": "> 0"}',
      update_content_adjustment: '{"direction": "up"}'
    )

    # They say content is too easy (2)
    AutoResponse.find_or_create_by!(
      trigger_phrase: "2",
      response: "Every baby develops at their own pace, and we’ve designed our content to match a range of developmental stages. To adjust, pick the animal that sounds most like your little one right now.\n{{content_age_groups}}",
      user_conditions: '{"contactable": true}',
      update_user: "{}",
      content_adjustment_conditions: '{"needs_adjustment": true, "direction": null, "number_down_options": "> 0"}',
      update_content_adjustment: '{"direction": "down"}'
    )

    #  They specify the group that they belong to (1)
    AutoResponse.find_or_create_by!(
      trigger_phrase: "1",
      response: "Thanks, we've adjusted the content you'll receive. We'll check back in in a few weeks to make sure it's right.",
      user_conditions: '{"contactable": true}',
      update_user: "{}",
      content_adjustment_conditions: '{"needs_adjustment": true, "direction": "down", "number_down_options": "> 0"}',
      update_content_adjustment: '{"needs_adjustment": false, "adjusted_at": "now"}'
    )
    AutoResponse.find_or_create_by!(
      trigger_phrase: "1",
      response: "Thanks, we've adjusted the content you'll receive. We'll check back in in a few weeks to make sure it's right.",
      user_conditions: '{"contactable": true}',
      update_user: "{}",
      content_adjustment_conditions: '{"needs_adjustment": true, "direction": "up", "number_up_options": "> 0"}',
      update_content_adjustment: '{"needs_adjustment": false, "adjusted_at": "now"}'
    )

    #  They specify the group that they belong to (2)
    AutoResponse.find_or_create_by!(
      trigger_phrase: "2",
      response: "Thanks, we've adjusted the content you'll receive. We'll check back in in a few weeks to make sure it's right.",
      user_conditions: '{"contactable": true}',
      update_user: "{}",
      content_adjustment_conditions: '{"needs_adjustment": true, "direction": "up", "number_up_options": 2}',
      update_content_adjustment: '{"needs_adjustment": false, "adjusted_at": "now"}'
    )
    AutoResponse.find_or_create_by!(
      trigger_phrase: "2",
      response: "Thanks, we've adjusted the content you'll receive. We'll check back in in a few weeks to make sure it's right.",
      user_conditions: '{"contactable": true}',
      update_user: "{}",
      content_adjustment_conditions: '{"needs_adjustment": true, "direction": "down", "number_down_options": 2}',
      update_content_adjustment: '{"needs_adjustment": false, "adjusted_at": "now"}'
    )

    #  They're not sure which group they belong to (3)
    AutoResponse.find_or_create_by!(
      trigger_phrase: "3",
      response: "Thanks, a member of the team will be in touch to discuss your child's needs.",
      user_conditions: '{"contactable": true}',
      update_user: "{}",
      content_adjustment_conditions: '{"needs_adjustment": true, "direction": "up", "number_up_options": 2}',
      update_content_adjustment: '{"direction": "not_sure"}'
    )
    AutoResponse.find_or_create_by!(
      trigger_phrase: "3",
      response: "Thanks, a member of the team will be in touch to discuss your child's needs.",
      user_conditions: '{"contactable": true}',
      update_user: "{}",
      content_adjustment_conditions: '{"needs_adjustment": true, "direction": "down", "number_down_options": 2}',
      update_content_adjustment: '{"direction": "not_sure"}'
    )

    #  They're not sure which group they belong to and there's only one other option (2)
    AutoResponse.find_or_create_by!(
      trigger_phrase: "2",
      response: "Thanks, a member of the team will be in touch to discuss your child's needs.",
      user_conditions: '{"contactable": true}',
      update_user: "{}",
      content_adjustment_conditions: '{"needs_adjustment": true, "direction": "up", "number_up_options": 1}',
      update_content_adjustment: '{"direction": "not_sure"}'
    )
    AutoResponse.find_or_create_by!(
      trigger_phrase: "2",
      response: "Thanks, a member of the team will be in touch to discuss your child's needs.",
      user_conditions: '{"contactable": true}',
      update_user: "{}",
      content_adjustment_conditions: '{"needs_adjustment": true, "direction": "down", "number_down_options": 1}',
      update_content_adjustment: '{"direction": "not_sure"}'
    )

    AutoResponse.find_or_create_by!(
      trigger_phrase: "adjust",
      response: "Are the activities we send you suitable for your child? Respond 'Yes' or 'No' to let us know.",
      user_conditions: '{"contactable": true}',
      content_adjustment_conditions: "{}",
      update_user: '{"asked_for_feedback": true}',
      update_content_adjustment: '{"id": true}'
    )
  end
end
