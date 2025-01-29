class ResponseMatcherService
  def initialize(message)
    @message = message
    @user = message.user
  end

  def match_response
    response = AutoResponse.find_by(trigger_phrase: @message.body.downcase.strip)

    if response && conditions_met?(response.conditions)
      send_message(response.response) if response.response.present?

      apply_user_updates(response.update_user)
    elsif Time.current.wday == 6 || Time.current.wday == 0
      # Send a out of office message on weekends
      send_message("The team's working hours are 9am - 6pm, Monday to Friday. We'll get back to you as soon as we can.")
    end
  end

  private

  def send_message(body)
    reply = Message.new(user: @user, body:)
    SendCustomMessageJob.perform_later(reply) if reply.save
  end

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
