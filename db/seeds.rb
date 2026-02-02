return unless Rails.env.development?

Admin.create!(email: "admin@example.com", password: "password")

group = Group.create!(name: "17 months (default order)", age_in_months: 17)

3.times do |i|
  Content.create!(
    group:,
    body: "my great message #{i}",
    link: "https://www.example#{i}.com",
    position: i + 1,
  )
end
