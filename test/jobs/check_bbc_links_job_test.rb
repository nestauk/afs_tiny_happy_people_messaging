require "test_helper"

class CheckBbcLinksJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform checks BBC links and logs errors" do
    stub_request(:get, /www.bbc.co.uk\/some-valid-link/).to_return(status: 200)
    stub_request(:get, /www.bbc.co.uk\/some-invalid-link/).to_return(status: 200)

    create(:content, link: "https://www.bbc.co.uk/some-valid-link")
    create(:content, link: "https://www.bbc.co.uk/some-invalid-link")

    stub_request(:get, "https://www.bbc.co.uk/some-valid-link")
      .to_return(status: 200, body: "OK")
    stub_request(:get, "https://www.bbc.co.uk/some-invalid-link")
      .to_return(status: 404, body: "Not Found")

    Appsignal.expects(:report_error).once.with do |message|
      message.include?("Link https://www.bbc.co.uk/some-invalid-link returned status code 404")
    end

    CheckBbcLinksJob.new.perform
  end
end
