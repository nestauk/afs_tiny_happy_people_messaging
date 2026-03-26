class PostcodeService
  def self.valid_welsh_postcode?(postcode)
    return false if postcode.blank?

    LocationGeocoder.new(postcode).geocode.country_code == "Wales"
  rescue Geokit::Geocoders::GeocodeError
    false
  end
end
