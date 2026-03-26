require "test_helper"

class PostcodeServiceTest < ActiveSupport::TestCase
  test "valid_welsh_postcode? returns true for a valid Welsh postcode" do
    geocode_payload = Geokit::GeoLoc.new(country_code: "Wales")
    LocationGeocoder.any_instance.stubs(:geocode).returns(geocode_payload)

    assert PostcodeService.valid_welsh_postcode?("CF61 1ZH")
  end

  test "valid_welsh_postcode? returns false for an invalid Welsh postcode" do
    geocode_payload = Geokit::GeoLoc.new(country_code: "England")
    LocationGeocoder.any_instance.stubs(:geocode).returns(geocode_payload)

    assert_not PostcodeService.valid_welsh_postcode?("ABC123")
  end
end
