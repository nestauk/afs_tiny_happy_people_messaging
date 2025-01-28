class ResponseMatcherService
  def initialize(message)
    @message = message
    @user = message.user
  end

  def match_response
    response = AutoResponse.find_by(trigger_phrase: @message.body.downcase.strip)

    if response && conditions_met?(response.conditions)
      if response.response.present?
        reply = Message.new(user: @user, body: response.response)

        SendCustomMessageJob.perform_later(reply) if reply.save
      end

      apply_user_updates(response.update_user)
    end
  end

  private

  def conditions_met?(conditions)
    conditions = JSON.parse(conditions)
    return true unless conditions.any?

    conditions.each do |key, value|
      return false unless @user[key] == value
    end

    true
  end

  def apply_user_updates(updates)
    updates = JSON.parse(updates)
    return unless updates.any?

    updates.each do |key, value|
      if key == "restart_at"
        @user.update(restart_at: 4.weeks.from_now.noon)
      else
        @user.update(key => value)
      end
    end
  end
end
