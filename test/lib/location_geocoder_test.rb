require "test_helper"
require "location_geocoder"

class LocationGeocoderTest < ActiveSupport::TestCase
  test "uses geokit to geocode the location" do
    location = "location"
    Geokit::LatLng.stubs(:normalize).with(location).returns("geocoded-location")
    assert_equal "geocoded-location", LocationGeocoder.new(location).geocode
  end

  test "retries geocoding 3 times" do
    location = "location"
    Geokit::LatLng.stubs(:normalize).with(location)
      .raises(Geokit::Geocoders::GeocodeError).then
      .raises(Geokit::Geocoders::GeocodeError).then
      .returns("geocoded-location")
    assert_equal "geocoded-location", LocationGeocoder.new(location).geocode
  end

  test "returns nil if geocoding fails 3 times" do
    location = "location"
    Geokit::LatLng.stubs(:normalize).with(location).raises(Geokit::Geocoders::GeocodeError).times(3)
    assert_nil LocationGeocoder.new(location).geocode
  end
end
