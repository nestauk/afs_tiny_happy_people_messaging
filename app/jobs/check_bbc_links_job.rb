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
            Appsignal.report_error("Link #{link} returned status code #{response.code}")
          end
        rescue => e
          Appsignal.report_error(e)
        end
      end
    end
  end
end
