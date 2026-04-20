class AnonymiseUsersJob < ApplicationJob
  queue_as :background

  def perform(*args)
    User.where("created_at < ? AND anonymised_at IS NULL", 3.years.ago).find_each do |user|
      user.anonymise!
    end
  rescue => e
    Appsignal.report_error(e)
  end
end
