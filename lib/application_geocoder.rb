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
        loc.district = result_json["properties"]["context"]["locality"]["name"]
        set_address_components(result_json, loc)
        set_precision(loc)
        set_bounds(result_json["properties"]["bbox"], loc)
        loc.success = true
        loc
      end
    end
  end
end
