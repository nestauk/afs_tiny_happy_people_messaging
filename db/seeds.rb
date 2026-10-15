return unless Rails.env.development?

Admin.find_or_create_by!(email: "admin@example.com")

group = Group.find_or_create_by!(name: "17 months (default order)", language: "en")

contents = 3.times.map do |i|
  Content.find_or_create_by!(group:, position: i + 1) do |content|
    content.age_in_months = 17
    content.body = "Tip #{i + 1}: talk to your child while you cook"
    content.link = "https://www.example#{i + 1}.com"
  end
end

statuses = %w[delivered sent failed]

%w[Amira Ben Chloe Dev Ella].each_with_index do |name, i|
  user = User.find_or_create_by!(phone_number: "+44770090000#{i + 1}") do |u|
    u.first_name = name
    u.postcode = "CF61 1ZH"
    u.child_birthday = (12 + i).months.ago
    u.terms_agreed_at = Time.zone.now
    u.contactable = true
    u.cohort = :first_uk
    u.group = group
  end

  unless user.messages.sent.exists?
    contents.each_with_index do |content, j|
      sent_at = (10 - j * 3 - i).days.ago
      status = statuses[(i + j) % 3]

      Message.create!(
        user:, content:, body: content.body, link: content.link,
        status:, sent_at:, send_attempts: (status == "failed") ? 2 : 1,
        clicked_at: (sent_at + 1.hour if status == "delivered" && j.zero?)
      )
    end
  end

  unless user.messages.exists?(status: "received")
    Message.insert!(
      {user_id: user.id, body: "Thanks, that was really useful!", status: "received", created_at: (2 + i).days.ago},
    )
  end
end
