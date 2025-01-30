require "test_helper"

class LocationGeocoderTest < ActiveSupport::TestCase
  test "uses geokit to geocode the location" do
    location = "location"
    stub_request(:get, "https://api.mapbox.com/search/geocode/v6/forward?access_token=key&country=uk").with(query: {"q" => "location"})
    Geokit::Geocoders::MultiGeocoder.stubs(:do_geocode).with(location).returns("geocoded-location")
    assert_equal "geocoded-location", LocationGeocoder.new(location).geocode
  end

  test "retries geocoding 3 times" do
    location = "location"
    Geokit::Geocoders::MultiGeocoder.stubs(:do_geocode).with(location)
      .raises(Geokit::Geocoders::GeocodeError).then
      .raises(Geokit::Geocoders::GeocodeError).then
      .returns("geocoded-location")
    assert_equal "geocoded-location", LocationGeocoder.new(location).geocode
  end

  test "returns nil if geocoding fails 3 times" do
    location = "location"
    Geokit::Geocoders::MultiGeocoder.stubs(:do_geocode).with(location).raises(Geokit::Geocoders::GeocodeError).times(3)
    assert_nil LocationGeocoder.new(location).geocode
  end
end
