FactoryBot.define do
  factory :content do
    body { "Sample Body" }
    link { "https://www.example.com" }
    age_in_months { 18 }
    sequence(:position) { |n| n }

    group

    after(:build) do |content|
      content.stubs(:valid_link?).returns(true)
    end
  end
end
