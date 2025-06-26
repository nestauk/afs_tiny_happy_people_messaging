class ResponseMatcherService
  def initialize(message)
    @message = message
    @user = message.user
  end

  def match_response
    responses = AutoResponse.where(trigger_phrase: @message.body.downcase.strip)

    return unless responses.any?

    responses.each do |response|
      process_response(response) and return
    end
  end

  private

  def process_response(response)
    if response && conditions_met?(response)

      # # Work out how to send the right groups to the user
      send_message(create_response_message(response)) if response.response.present?
      ## Apply content updates to the user
      apply_updates(response)
    elsif Time.current.wday == 6 || Time.current.wday == 0
      # Send a out of office message on weekends
      send_message("The team's working hours are 9am - 6pm, Monday to Friday. We'll get back to you as soon as we can.")
    end
  end

  def send_message(body)
    reply = Message.new(user: @user, body:)
    SendCustomMessageJob.perform_later(reply) if reply.save
  end

  def conditions_met?(conditions)
    check_conditions(conditions.user_conditions, @user) &&
      check_conditions(conditions.content_adjustment_conditions, @user.content_adjustment)
  end

  def check_conditions(conditions, object)
    conditions = JSON.parse(conditions)
    return true unless conditions.any?

    conditions.each do |key, value|
      if key == "direction" && value == "not_nil"
        return false if object[key].nil?
      elsif object[key] != value
        return false
      end
    end

    true
  end

  def apply_updates(response)
    apply_user_updates(response.update_user)
    apply_content_adjustment_updates(response.update_content_adjustment)
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

  def apply_content_adjustment_updates(updates)
    updates = JSON.parse(updates)
    return unless updates.any?

    updates.each do |key, value|
      if key == "adjusted_at"
        @user.content_adjustment.update(adjusted_at: Time.current)
      else
        @user.content_adjustment.update(key => value)
      end
    end
  end

  def create_response_message(response)
    if @user.needs_content_group_suggestions?
      response.response.gsub(/{{user_name}}/, @user.first_name)
    else
      response.response
    end
  end
end
