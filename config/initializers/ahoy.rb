class Ahoy::Store < Ahoy::DatabaseStore
end

# set to true for JavaScript tracking
Ahoy.api = false

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false

# Don't collect cookies
Ahoy.cookies = :none
Ahoy.mask_ips = true

Ahoy.user_method = :current_admin

Ahoy.exclude_method = lambda do |controller, _request|
  controller.send(:cookies)[:ahoy_dnt] == "1" unless controller.nil?
end

module Ahoy
  class Tracker
    def visitor_anonymity_set
      # If the user has requested anonymity, do not track across visits
      return "dnt-#{SecureRandom.hex(16)}" if request.cookies["ahoy_dnt"] == "1"

      @visitor_anonymity_set ||= Digest::UUID.uuid_v5(UUID_NAMESPACE, [
        "visitor",
        Ahoy.mask_ip(request.remote_ip),
        request.user_agent,
        anonymity_set_pepper,
      ].join("/"))
    end

    # A transient pepper is used to hash the visitor's private data. This pepper expires daily at 3am
    # at which point the pepper is renewed and existing data becomes aggregated.
    # See https://ico.org.uk/for-organisations/direct-marketing-and-privacy-and-electronic-communications/guidance-on-the-use-of-storage-and-access-technologies/what-are-the-exceptions/#statistical
    private def anonymity_set_pepper
      pepper_expiry = ((Time.current.hour < 3) ? Time.current : Time.current.tomorrow).change(hour: 3) - Time.current

      Rails.cache.fetch("ahoy_anonymity_pepper", expires_in: pepper_expiry.to_i) do
        SecureRandom.hex(32)
      end
    end
  end
end
