require "test_helper"
require "webmock/minitest"

class ApplicationGeocoderTest < ActiveSupport::TestCase
  test "makes a query to the Mapbox endpoint" do
    Geokit::Geocoders::MapboxGeocoder.stubs(:key).returns("key")
    stub_request(:get, "https://api.mapbox.com/search/geocode/v6/forward?access_token=key&country=uk").with(query: {"q" => "London"})

    Geokit::Geocoders::ApplicationGeocoder.geocode("London")
  end

  test "raises an exception if the MapboxGeocoder key is nil" do
    Geokit::Geocoders::MapboxGeocoder.expects(:key).returns(nil)

    assert_raises(Geokit::Geocoders::GeocodeError) do
      Geokit::Geocoders::ApplicationGeocoder.geocode("London")
    end
  end

  test "raises an exception if the GeonamesGeocoder key is blank" do
    Geokit::Geocoders::MapboxGeocoder.expects(:key).at_least_once.returns("")

    assert_raises(Geokit::Geocoders::GeocodeError) do
      Geokit::Geocoders::ApplicationGeocoder.geocode("London")
    end
  end

  test "extract_geoloc correctly parses the result JSON for Greater London" do
    result_json = {
      "properties" => {
        "context" => {
          "district" => {"name" => "Greater London"},
          "locality" => {"name" => "London"},
          "region" => {"name" => "UK"}
        }
      }
    }

    geoloc = Geokit::Geocoders::ApplicationGeocoder.send(:extract_geoloc, result_json)

    assert_equal "London", geoloc.state
    assert_equal "UK", geoloc.country_code
    assert geoloc.success
  end

  test "extract_geoloc correctly parses the result JSON for places other than London" do
    result_json = {
      "properties" => {
        "context" => {
          "district" => {"name" => "Manchester"},
          "region" => {"name" => "UK"}
        }
      }
    }

    geoloc = Geokit::Geocoders::ApplicationGeocoder.send(:extract_geoloc, result_json)

    assert_equal "Manchester", geoloc.state
    assert_equal "UK", geoloc.country_code
    assert geoloc.success
  end

  test "parse_json returns a GeoLoc object with extracted data when features are present" do
    results = {
      "features" => [
        {
          "properties" => {
            "context" => {
              "district" => {"name" => "Greater London"},
              "locality" => {"name" => "London"},
              "region" => {"name" => "UK"}
            }
          }
        }
      ]
    }

    geoloc = Geokit::Geocoders::ApplicationGeocoder.send(:parse_json, results)

    assert_equal "London", geoloc.state
    assert_equal "UK", geoloc.country_code
    assert geoloc.success
  end
end
