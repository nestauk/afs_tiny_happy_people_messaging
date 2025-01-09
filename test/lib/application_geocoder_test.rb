require "test_helper"
require "webmock/minitest"
require "application_geocoder"

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
end
