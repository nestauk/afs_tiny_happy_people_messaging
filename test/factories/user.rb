FactoryBot.define do
  factory :user do
    first_name { "Ali" }
    sequence(:phone_number) { |n| "07" + n.to_s.rjust(9, "0") }
    child_birthday { 18.months.ago }
    terms_agreed_at { Time.zone.now }
    contactable { true }
    postcode { "CF61 1ZH" }
  end
end
