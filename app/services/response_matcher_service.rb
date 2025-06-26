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
    if conditions_met?(response)
      apply_updates(response)

      send_message(create_response_message(response)) if response.response.present?
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
    apply_user_updates(response)
    apply_content_adjustment_updates(response)
  end

  def apply_user_updates(response)
    if @user.needs_new_content_group?
      months = find_groups[response.trigger_phrase.to_i - 1].min_months

      @user.update(last_content_id: Content.where(age_in_months: months).min_by(&:position).id)
    end

    updates = JSON.parse(response.update_user)
    return unless updates.any?

    updates.each do |key, value|
      if key == "restart_at"
        @user.update(restart_at: 4.weeks.from_now.noon)
      else
        @user.update(key => value)
      end
    end
  end

  def apply_content_adjustment_updates(response)
    updates = JSON.parse(response.update_content_adjustment)
    return unless updates.any?

    updates.each do |key, value|
      if key == "adjusted_at"
        @user.content_adjustment.update(adjusted_at: Time.current)
      elsif value == "number_options"
        @user.content_adjustment.update(number_options: find_groups.size)
      else
        @user.content_adjustment.update(key => value)
      end
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

    content.gsub("{{content_age_groups}}", "#{sentences.join(", ")}, #{sentences.length + 1}. I'm not sure")
  end

  def find_groups
    direction = @user.content_adjustment.needs_older_content? ? ">" : "<"

    ContentAgeGroup.return_two_groups(direction, @user.child_age_in_months_today)
  end

  def generate_sentences
    find_groups.map.each_with_index do |group, index|
      "#{index + 1}. #{group.description}"
    end
  end
end
