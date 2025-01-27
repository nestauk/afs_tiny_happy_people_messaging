WITH total_users AS (
  SELECT COUNT(*) AS total_user_count
  FROM users
  WHERE contactable = 'true'
),
new_users_this_month AS (
  SELECT COUNT(*) AS new_users_this_month_count
  FROM users
  WHERE DATE_TRUNC('month', created_at)::DATE >= DATE_TRUNC('month', CURRENT_DATE)::DATE
  AND contactable = 'true'
),
new_users_this_year AS (
  SELECT COUNT(*) AS new_users_this_year_count
  FROM users
  WHERE contactable = 'true'
  AND DATE_TRUNC('year', created_at)::DATE >= DATE_TRUNC('year', CURRENT_DATE)::DATE
),
average_overall_clickthrough_rates AS (
  SELECT (COUNT(clicked_at)::numeric / NULLIF(COUNT(*)::numeric, 0)) * 100 AS average_overall_clickthrough_rates
  FROM messages
  INNER JOIN users ON messages.user_id = users.id
  WHERE content_id IS NOT NULL
  AND users.contactable = 'true'
),
average_month_clickthrough_rates AS (
  SELECT (COUNT(clicked_at)::numeric / NULLIF(COUNT(*)::numeric, 0)) * 100 AS average_this_month_clickthrough_rates
  FROM messages
  INNER JOIN users ON messages.user_id = users.id
  WHERE content_id IS NOT NULL
  AND DATE_TRUNC('month', messages.created_at)::DATE >= DATE_TRUNC('month', current_date)::DATE
  AND users.contactable = 'true'
)
SELECT total_users.total_user_count, 
  new_users_this_month.new_users_this_month_count,
  new_users_this_year.new_users_this_year_count,
  average_overall_clickthrough_rates.average_overall_clickthrough_rates,
  average_month_clickthrough_rates.average_this_month_clickthrough_rates
FROM total_users, 
  new_users_this_month,
  new_users_this_year,
  average_overall_clickthrough_rates,
  average_month_clickthrough_rates
