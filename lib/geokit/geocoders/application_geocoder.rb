require "geokit"

module Geokit
  module Geocoders
    class ApplicationGeocoder < MapboxGeocoder
      private_class_method

      def self.do_geocode(address)
        if key.nil? || key.empty?
          raise(Geokit::Geocoders::GeocodeError, "Mapbox requires a key to use their service.")
        end

        address_str = address.is_a?(GeoLoc) ? address.to_geocodeable_s : address
        url = "https://api.mapbox.com/search/geocode/v6/forward?"
        url += "q=#{Geokit::Inflector.url_escape(address_str)}&access_token=#{key}&country=uk"
        process :json, url
      end

      def self.extract_geoloc(result_json)
        loc = new_loc
        loc.state = result_json["properties"]["context"]["locality"]["name"]
        loc.success = true
        loc
      end
    end
  end
end
