class AutoResponseMatch
  include ActiveModel::Model

  attr_accessor :message
  delegate :user, to: :message

  def deliver
    responses = AutoResponse.where(trigger_phrase: normalized_body)

    if responses.any?
      responses.each { |r| process_response(r) and break if conditions_met?(r) }
    elsif weekend?
      send_message(I18n.t(".messages.out_of_hours_response", locale: user.language))
    end
  end

  private

  def normalized_body
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
    reply = Message.new(user: user, body:)
    SendCustomMessageJob.perform_later(reply) if reply.save
  end

  def conditions_met?(response)
    check_conditions(response.user_conditions, user)
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
    updates.each { |key, value| update_attribute(key, value, user) } if updates.any?
  end

  def update_attribute(key, value, object)
    object.update(key => value)
  end
end
