class ResponseMatcherJob < ApplicationJob
  queue_as :background

  def perform(message)
    ResponseMatcherService.new(message).match_response
  end
end
