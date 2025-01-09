FactoryBot.define do
  factory :user do
    first_name { "Ali" }
    last_name { "Smith" }
    sequence(:phone_number) { |n| "07#{n}23456789" }
    child_birthday { Time.now - 18.months }
    terms_agreed_at { Time.now }
    contactable { true }
    postcode { "ABC123" }
  end
end
