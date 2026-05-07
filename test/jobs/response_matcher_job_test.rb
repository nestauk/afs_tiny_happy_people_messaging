require "test_helper"

class ResponseMatcherJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform delegates to ResponseMatcherService" do
    message = create(:message)
    service = mock
    service.expects(:match_response).once
    ResponseMatcherService.expects(:new).with(message).returns(service)

    ResponseMatcherJob.new.perform(message)
  end

  test ".perform_later enqueues the job on the background queue" do
    message = create(:message)

    assert_enqueued_with(job: ResponseMatcherJob, args: [message], queue: "background") do
      ResponseMatcherJob.perform_later(message)
    end
  end
end
