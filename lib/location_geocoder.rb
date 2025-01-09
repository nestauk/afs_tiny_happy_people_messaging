class LocationGeocoder
  RETRY_LIMIT = 3

  def initialize(location)
    @location = location
    @attempt = 1
  end

  def geocode
    Geokit::Geocoders::MultiGeocoder.geocode(@location)
  rescue Geokit::Geocoders::GeocodeError
    @attempt += 1
    retry if @attempt <= RETRY_LIMIT
  end
end
