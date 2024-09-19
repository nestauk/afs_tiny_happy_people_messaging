FactoryBot.define do
  factory :content do
    body { "Sample Body" }
    link { "www.example.com" }
    sequence(:position) { |n| n }

    group
  end
end
