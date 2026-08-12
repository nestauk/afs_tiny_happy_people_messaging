class AdminNotification < ApplicationRecord
  def self.already_sent_today?
    where(sent_on: Date.current).exists?
  end
end
