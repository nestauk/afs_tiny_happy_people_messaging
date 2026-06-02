class LocalAuthority < ApplicationRecord
  has_many :users
  has_many :messages, through: :users
  validates :name, presence: true

  scope :most_users_order, -> { left_joins(:users).group(:id).order("COUNT(users.id) DESC") }

  def count_users_by_created_at(timeframe)
    users
      .group(Arel.sql("to_char(users.created_at, '#{sql_format_for(timeframe)}')"))
      .count
  end

  def percentage_messages_clicked_by_created_at(timeframe)
    messages.with_content
      .group(Arel.sql("to_char(messages.created_at, '#{sql_format_for(timeframe)}')"))
      .pluck(
        Arel.sql("to_char(messages.created_at, '#{sql_format_for(timeframe)}')"),
        Arel.sql("(COUNT(messages.clicked_at)::float / COUNT(*)) * 100"),
      ).to_h
  end

  def count_messages_by_created_at(timeframe)
    messages.with_content
      .group(Arel.sql("to_char(messages.created_at, '#{sql_format_for(timeframe)}')"))
      .count
  end

  private

  def sql_format_for(timeframe)
    case timeframe
    when "%B %Y"
      "FMMonth YYYY"
    when "%d %B %Y"
      "DD FMMonth YYYY"
    else
      raise ArgumentError, "Invalid timeframe: #{timeframe}"
    end
  end
end
