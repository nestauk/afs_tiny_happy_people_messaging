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

Ahoy.user_method = :current_admin

module AhoyRandomVisitorToken
  def visitor_anonymity_set
    @visitor_anonymity_set ||= SecureRandom.hex(16)
  end
end

Ahoy::Tracker.prepend(AhoyRandomVisitorToken)
