if Rails.env == 'development'
  cg = ContentGroup.create!(name: '17-18 months', age_in_months: 17)

  3.times do |i|
    Content.create!(body: "my great message #{i}", position: i + 1, content_group: cg, link: "https://www.example#{i}.com")
  end
end
