class ResponseMatcherJob < ApplicationJob
  queue_as :default

  def perform(message)
    ResponseMatcherService.new(message).match_response
  end
end
