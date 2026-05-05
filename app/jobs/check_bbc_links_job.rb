require "net/http"
require "uri"

class CheckBbcLinksJob < ApplicationJob
  queue_as :background

  def perform
    Appsignal::CheckIn.cron("check_bbc_links_job") do
      Content.active.find_each do |content|
        next if content.link.blank?
        check(content)
      end
    end
  end

  def check(content)
    uri = URI.parse(content.link)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 5
    http.read_timeout = 5
    response = http.request(Net::HTTP::Get.new(uri))
    return if response.code == "200"
    Appsignal.report_error(StandardError.new("Link #{content.link} returned #{response.code}"))
  rescue *HTTP_ERRORS => e
    Appsignal.report_error(e)
  end

  HTTP_ERRORS = [Timeout::Error, Errno::ECONNRESET, Net::HTTPBadResponse,
    SocketError, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError, URI::InvalidURIError].freeze
end
