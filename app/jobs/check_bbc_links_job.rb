require "net/http"
require "uri"

class CheckBbcLinksJob < ApplicationJob
  queue_as :background

  def perform
    Appsignal::CheckIn.cron("check_bbc_links_job") do
      Content.pluck(:link).each do |link|
        uri = URI.parse(link)

        begin
          response = Net::HTTP.get_response(uri)

          if response.code != "200"
            error = StandardError.new("Link #{link} returned status code #{response.code}")
            Appsignal.report_error(error)
          end
        rescue => e
          Appsignal.report_error(e)
        end
      end
    end
  end
end
