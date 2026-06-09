require "test_helper"

class RegistrationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup { create(:group) }

  def valid_user_params(overrides = {})
    {
      phone_number: "07712345678",
      child_birthday: 18.months.ago.to_date,
      postcode: "CF61 1ZH",
      child_name: "Maya",
      terms_agreed: "1",
    }.merge(overrides)
  end

  def empty_referrer_params
    {utm_source: nil, utm_medium: nil, utm_campaign: nil, utm_term: nil, utm_content: nil, gclid: nil}
  end

  test "#submit creates a user from user_params and returns true" do
    registration = Registration.new(user_params: valid_user_params, referrer_params: empty_referrer_params)

    assert_difference -> { User.count }, 1 do
      assert registration.submit
    end
    assert registration.user.persisted?
    assert_equal "+447712345678", registration.user.phone_number.delete(" ")
  end

  test "#submit returns false when the user cannot be saved" do
    registration = Registration.new(user_params: valid_user_params(phone_number: nil), referrer_params: empty_referrer_params)

    assert_no_difference -> { User.count } do
      assert_not registration.submit
    end
  end

  test "#submit exposes the unsaved user with errors when save fails" do
    registration = Registration.new(user_params: valid_user_params(phone_number: nil), referrer_params: empty_referrer_params)
    registration.submit

    assert_not registration.user.persisted?
    assert_includes registration.user.errors[:phone_number], "can't be blank"
  end

  test "#submit stamps terms_agreed_at to now when terms_agreed is '1'" do
    freeze_time do
      registration = Registration.new(user_params: valid_user_params(terms_agreed: "1"), referrer_params: empty_referrer_params)
      registration.submit

      assert_equal Time.zone.now, registration.user.terms_agreed_at
    end
  end

  test "#submit does not stamp terms_agreed_at when terms_agreed is not '1'" do
    registration = Registration.new(user_params: valid_user_params(terms_agreed: "0"), referrer_params: empty_referrer_params)
    registration.submit

    assert_nil registration.user.terms_agreed_at
  end

  test "#submit updates the user's local authority on success" do
    LocationGeocoder.any_instance.stubs(:geocode).returns(Geokit::GeoLoc.new(state: "Cardiff", country_code: "Wales"))
    registration = Registration.new(user_params: valid_user_params, referrer_params: empty_referrer_params)

    registration.submit

    assert_equal "Cardiff", registration.user.local_authority.name
    assert_equal "Wales", registration.user.local_authority.country
  end

  test "#submit creates a UserReferrer when any referrer param is present" do
    referrer_params = empty_referrer_params.merge(utm_source: "facebook", utm_campaign: "spring")
    registration = Registration.new(user_params: valid_user_params, referrer_params: referrer_params)

    assert_difference -> { UserReferrer.count }, 1 do
      registration.submit
    end
    referrer = UserReferrer.last
    assert_equal "facebook", referrer.utm_source
    assert_equal "spring", referrer.utm_campaign
  end

  test "#submit does not create a UserReferrer when all referrer params are blank" do
    registration = Registration.new(user_params: valid_user_params, referrer_params: empty_referrer_params)

    assert_no_difference -> { UserReferrer.count } do
      registration.submit
    end
  end

  test "#submit puts the user on the waitlist when the child is too young" do
    user_params = valid_user_params(child_birthday: 6.months.ago.to_date, skip_age_validation: "true")
    registration = Registration.new(user_params: user_params, referrer_params: empty_referrer_params)

    User.any_instance.expects(:put_on_waitlist).once

    assert registration.submit
  end

  test "#submit does not put the user on the waitlist when the child is old enough" do
    registration = Registration.new(user_params: valid_user_params, referrer_params: empty_referrer_params)

    User.any_instance.expects(:put_on_waitlist).never

    assert registration.submit
  end

  test "#waitlisted? is true when the child is younger than 9 months" do
    registration = Registration.new(
      user_params: valid_user_params(child_birthday: 6.months.ago.to_date, skip_age_validation: "true"),
      referrer_params: empty_referrer_params,
    )
    User.any_instance.stubs(:put_on_waitlist)
    registration.submit

    assert registration.waitlisted?
  end

  test "#waitlisted? is false when the child is older than 9 months" do
    registration = Registration.new(
      user_params: valid_user_params(child_birthday: 12.months.ago.to_date),
      referrer_params: empty_referrer_params,
    )
    registration.submit

    assert_not registration.waitlisted?
  end
end
