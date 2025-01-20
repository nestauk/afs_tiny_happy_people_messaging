class LocalAuthority < ApplicationRecord
  has_many :users
  has_many :messages, through: :users
  validates :name, presence: true

  scope :most_users_order, -> { left_joins(:users).group(:id).order("COUNT(users.id) DESC") }

  def count_users_by_created_at(timeframe)
    users
      .group_by { |user| user.created_at.strftime(timeframe) }
      .transform_values { |values| values.count }
  end

  def percentage_messages_clicked_by_created_at(timeframe)
    messages.with_content
      .group_by { |message| message.created_at.strftime(timeframe) }
      .transform_values { |values| ((values.select { |m| !m.clicked_at.nil? }).count.to_f / values.count.to_f) * 100 }
  end

  def count_messages_by_created_at(timeframe)
    messages.with_content
      .group_by { |message| message.created_at.strftime(timeframe) }
      .transform_values { |values| values.count }
  end
end
