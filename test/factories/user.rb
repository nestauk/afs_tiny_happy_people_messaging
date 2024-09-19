FactoryBot.define do
  factory :user do
    first_name { "Ali" }
    last_name { "Smith" }
    sequence(:phone_number) { |n| "07#{n}23456789" }
    child_age { 18 }
  end
end
