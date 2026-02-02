require "geokit"

module Geokit
  module Geocoders
    class ApplicationGeocoder < MapboxGeocoder
      private_class_method

      def self.do_geocode(address)
        if key.blank?
          raise(Geokit::Geocoders::GeocodeError, "Mapbox requires a key to use their service.")
        end

        address_str = address.is_a?(GeoLoc) ? address.to_geocodeable_s : address
        url = "https://api.mapbox.com/search/geocode/v6/forward?"
        url += "q=#{Geokit::Inflector.url_escape(address_str)}&access_token=#{key}&country=uk"
        process :json, url
      end

      def self.parse_json(results)
        return GeoLoc.new unless results["features"].count > 0
        loc = nil

        extracted_geoloc = extract_geoloc(results["features"].first)
        if loc.nil?
          loc = extracted_geoloc
        else
          loc.all.push(extracted_geoloc)
        end
        loc
      end

      def self.extract_geoloc(result_json)
        loc = new_loc
        loc.state = if result_json["properties"]["context"]["district"]["name"] == "Greater London"
          if result_json["properties"]["context"]["locality"]
            result_json["properties"]["context"]["locality"]["name"]
          else
            result_json["properties"]["context"]["place"]["name"]
          end
        else
          result_json["properties"]["context"]["district"]["name"]
        end

        loc.country_code = result_json["properties"]["context"]["region"]["name"]

        loc.success = true
        loc
      end
    end
  end
end
