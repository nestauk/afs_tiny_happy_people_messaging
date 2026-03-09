class ResponseMatcherService
  WORKING_HOURS_MESSAGE = "The team's working hours are 9am - 6pm, Monday to Friday. We'll get back to you as soon as we can."

  def initialize(message)
    @message = message
    @user = message.user
  end

  def match_response
    responses = AutoResponse.where(trigger_phrase: normalized_message_body)

    if responses.any?
      responses.each do |response|
        process_response(response) and break if conditions_met?(response)
      end
    elsif weekend?
      send_message(WORKING_HOURS_MESSAGE)
    end
  end

  private

  def normalized_message_body
    @message.body.downcase.strip
  end

  def process_response(response)
    apply_updates(response)
    send_message(response.response) if response.response.present?
  end

  def weekend?
    Time.current.saturday? || Time.current.sunday?
  end

  def send_message(body)
    reply = Message.new(user: @user, body:)
    SendCustomMessageJob.perform_later(reply) if reply.save
  end

  def conditions_met?(response)
    check_conditions(response.user_conditions, @user)
  end

  def check_conditions(conditions, object)
    parsed_conditions = JSON.parse(conditions)
    return true if parsed_conditions.empty?

    parsed_conditions.all? do |key, value|
      object[key] == value
    end
  end

  def apply_updates(response)
    updates = JSON.parse(response.update_user)
    updates.each { |key, value| update_attribute(key, value, @user) } if updates.any?
  end

  def update_attribute(key, value, object)
    if key == "restart_at"
      object.update(restart_at: 4.weeks.from_now.noon)
    else
      object.update(key => value)
    end
  end
end
