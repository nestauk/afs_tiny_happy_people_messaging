require "test_helper"

class CheckBbcLinksJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform checks BBC links and logs errors" do
    create(:content, link: "https://www.bbc.co.uk/some-valid-link")
    create(:content, link: "https://www.bbc.co.uk/some-invalid-link")

    stub_request(:get, "https://www.bbc.co.uk/some-valid-link")
      .to_return(status: 200, body: "OK")
    stub_request(:get, "https://www.bbc.co.uk/some-invalid-link")
      .to_return(status: 404, body: "Not Found")

    Rollbar.expects(:error).once.with do |message|
      message.include?("Link https://www.bbc.co.uk/some-invalid-link returned status code 404")
    end

    CheckBbcLinksJob.new.perform
  end
end
