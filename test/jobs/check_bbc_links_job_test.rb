require "test_helper"

class CheckBbcLinksJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform checks BBC links and logs errors" do
    create(:content, link: "https://www.bbc.co.uk/some-valid-link")
    create(:content, link: "https://www.bbc.co.uk/some-invalid-link")
    create(:content, link: "https://www.example.com/other-link", archived_at: 1.day.ago)

    stub_request(:get, "https://www.bbc.co.uk/some-valid-link")
      .to_return(status: 200, body: "OK")
    stub_request(:get, "https://www.bbc.co.uk/some-invalid-link")
      .to_return(status: 404, body: "Not Found")
    stub_request(:get, "https://www.example.com/other-link")
      .to_return(status: 404, body: "Not Found")

    Appsignal.expects(:report_error).once.with do |error|
      error.message == "Link https://www.bbc.co.uk/some-invalid-link returned 404"
    end

    CheckBbcLinksJob.new.perform
  end
end
