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
    send_message(create_response_message(response)) if response.response.present?
  end

  def weekend?
    Time.current.saturday? || Time.current.sunday?
  end

  def send_message(body)
    reply = Message.new(user: @user, body:)
    SendCustomMessageJob.perform_later(reply) if reply.save
  end

  def conditions_met?(response)
    check_conditions(response.user_conditions, @user) &&
      check_conditions(response.content_adjustment_conditions, @user.latest_adjustment)
  end

  def check_conditions(conditions, object)
    parsed_conditions = JSON.parse(conditions)
    return true if parsed_conditions.empty?

    parsed_conditions.all? do |key, value|
      if key == "direction" && value == "not_nil"
        object[key].present?
      elsif value == "> 0"
        object[key].to_i > 0
      else
        object[key] == value
      end
    end
  end

  def apply_updates(response)
    update_user_content_group if @user.needs_new_content_group?

    updates = JSON.parse(response.update_user)
    updates.each { |key, value| update_attribute(key, value, @user) } if updates.any?

    updates = JSON.parse(response.update_content_adjustment)
    updates.each { |key, value| update_attribute(key, value, @user.latest_adjustment) } if updates.any?
  end

  def update_user_content_group
    months = find_groups[@message.body.to_i - 1].min_months
    content_id = Content.where(age_in_months: months).min_by(&:position).id

    @user.update(last_content_id: content_id)
  end

  def update_attribute(key, value, object)
    if key == "restart_at"
      object.update(restart_at: 4.weeks.from_now.noon)
    elsif key == "adjusted_at"
      object.update(adjusted_at: Time.current)
    elsif value == "number_options"
      object.update(number_options: find_groups.size)
    elsif key == "id" && value
      @user.content_adjustments.create
    else
      object.update(key => value)
    end
  end

  def create_response_message(response)
    if @user.needs_content_group_suggestions?
      substitute_variables(response.response)
    else
      response.response
    end
  end

  def substitute_variables(content)
    sentences = generate_sentences
    content.gsub("{{content_age_groups}}", "#{sentences.join("\n")}\n#{sentences.length + 1}. I'm not sure")
  end

  def find_groups
    direction = @user.latest_adjustment.needs_older_content? ? ">" : "<"
    ContentAgeGroup.return_two_groups(direction, @user.child_age_in_months_today)
  end

  def generate_sentences
    find_groups.map.with_index(1) { |group, index| "#{index}. #{group.description}" }
  end
end
