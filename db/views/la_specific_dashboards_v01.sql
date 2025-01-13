WITH la AS (
  SELECT id, name AS la_name
  FROM local_authorities
),
total_users AS (
  SELECT local_authority_id, COUNT(users) AS total_user_count
  FROM users
  GROUP BY local_authority_id
),
new_users_this_month AS (
  SELECT local_authority_id, COUNT(users) AS new_users_this_month_count
  FROM users
  WHERE DATE_TRUNC('month', created_at)::DATE >= DATE_TRUNC('month', CURRENT_DATE)::DATE
  GROUP BY local_authority_id
),
new_users_this_year AS (
  SELECT local_authority_id, COUNT(users) AS new_users_this_year_count
  FROM users
  WHERE DATE_TRUNC('year', created_at)::DATE >= DATE_TRUNC('year', CURRENT_DATE)::DATE
  GROUP BY local_authority_id
),
average_overall_clickthrough_rates AS (
  SELECT users.local_authority_id AS local_authority_id,
    (COUNT(clicked_at)::numeric / NULLIF(COUNT(*)::numeric, 0)) * 100 AS average_overall_clickthrough_rates
  FROM messages
  INNER JOIN users ON messages.user_id = users.id
  WHERE content_id IS NOT NULL
  GROUP BY users.local_authority_id
),
average_month_clickthrough_rates AS (
  SELECT users.local_authority_id AS local_authority_id,
    (COUNT(clicked_at)::numeric / NULLIF(COUNT(*)::numeric, 0)) * 100 AS average_this_month_clickthrough_rates
  FROM messages
  INNER JOIN users ON messages.user_id = users.id
  WHERE content_id IS NOT NULL
  AND DATE_TRUNC('month', messages.created_at)::DATE >= DATE_TRUNC('month', current_date)::DATE
  GROUP BY users.local_authority_id
)
SELECT 
  la.la_name,
  total_users.total_user_count,
  new_users_this_month.new_users_this_month_count,
  new_users_this_year.new_users_this_year_count,
  average_overall_clickthrough_rates.average_overall_clickthrough_rates,
  average_month_clickthrough_rates.average_this_month_clickthrough_rates
FROM
  la
LEFT JOIN total_users ON la.id = total_users.local_authority_id
LEFT JOIN new_users_this_month ON la.id = new_users_this_month.local_authority_id
LEFT JOIN new_users_this_year ON la.id = new_users_this_year.local_authority_id
LEFT JOIN average_overall_clickthrough_rates ON la.id = average_overall_clickthrough_rates.local_authority_id
LEFT JOIN average_month_clickthrough_rates ON la.id = average_month_clickthrough_rates.local_authority_id;
