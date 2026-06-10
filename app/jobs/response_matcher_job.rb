class ResponseMatcherJob < ApplicationJob
  queue_as :background

  def perform(message)
    AutoResponseMatch.new(message: message).deliver
  end
end
