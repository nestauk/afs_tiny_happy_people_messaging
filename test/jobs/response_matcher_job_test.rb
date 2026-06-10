require "test_helper"

class ResponseMatcherJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform delegates to AutoResponseMatch" do
    message = create(:message)

    AutoResponseMatch.expects(:new).with(message: message).returns(mock(deliver: true))

    ResponseMatcherJob.new.perform(message)
  end

  test ".perform_later enqueues the job on the background queue" do
    message = create(:message)

    assert_enqueued_with(job: ResponseMatcherJob, args: [message], queue: "background") do
      ResponseMatcherJob.perform_later(message)
    end
  end
end
