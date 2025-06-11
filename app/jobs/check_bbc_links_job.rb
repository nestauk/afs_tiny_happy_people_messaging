require "net/http"
require "uri"

class CheckBbcLinksJob < ApplicationJob
  queue_as :background

  def perform
    Content.pluck(:link).each do |link|
      uri = URI.parse(link)

      begin
        response = Net::HTTP.get_response(uri)

        if response.code != "200"
          Rollbar.error("Link #{link} returned status code #{response.code}")
        end
      rescue => e
        Rails.logger.error("Error checking link #{link}: #{e.message}")
      end
    end
  end
end
