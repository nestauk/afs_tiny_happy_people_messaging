# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_04_03_082226) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "admin", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.uuid "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.uuid "user_id"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "auto_responses", force: :cascade do |t|
    t.string "trigger_phrase", null: false
    t.string "response"
    t.jsonb "update_user", default: "{}"
    t.jsonb "conditions", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "query_id"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.text "slack_channels"
    t.string "check_type"
    t.text "message"
    t.datetime "last_run_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.bigint "dashboard_id"
    t.bigint "query_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "contents", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "link"
    t.bigint "group_id"
    t.integer "position", null: false
    t.integer "age_in_months", null: false
    t.datetime "archived_at"
    t.index ["group_id", "position"], name: "index_contents_on_group_id_and_position", unique: true
    t.index ["group_id"], name: "index_contents_on_group_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "demographic_data", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "gender"
    t.integer "age"
    t.integer "number_of_children"
    t.string "children_ages"
    t.string "country"
    t.string "ethnicity"
    t.string "education"
    t.string "marital_status"
    t.string "employment_status"
    t.string "household_income"
    t.boolean "receiving_credit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_demographic_data_on_user_id"
  end

  create_table "diary_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "days", default: [], array: true
    t.jsonb "timings", default: [], array: true
    t.integer "total_time"
    t.boolean "did_previous_week_activity"
    t.boolean "first_week"
    t.text "activities_from_previous_weeks"
    t.jsonb "feedback", default: [], array: true
    t.text "feedback_reason"
    t.text "reason_for_not_doing_activity"
    t.text "enjoyed_most"
    t.text "enjoyed_least"
    t.text "changes_to_make"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "video_message"
    t.index ["user_id"], name: "index_diary_entries_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "interests", force: :cascade do |t|
    t.bigint "user_id"
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_interests_on_user_id"
  end

  create_table "local_authorities", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "content_id"
    t.string "message_sid"
    t.string "status"
    t.datetime "sent_at"
    t.string "token", null: false
    t.string "link"
    t.datetime "clicked_at"
    t.datetime "marked_as_seen_at"
    t.index ["content_id"], name: "index_messages_on_content_id"
    t.index ["token"], name: "index_messages_on_token", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "phone_number", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "contactable", default: true
    t.date "child_birthday", null: false
    t.string "postcode", null: false
    t.string "hour_preference"
    t.datetime "terms_agreed_at", null: false
    t.datetime "restart_at"
    t.datetime "nudged_at"
    t.bigint "last_content_id"
    t.string "child_name"
    t.boolean "diary_study", default: false
    t.integer "day_preference", default: 1, null: false
    t.string "referral_source"
    t.string "email"
    t.uuid "uuid"
    t.bigint "local_authority_id"
    t.boolean "asked_for_feedback", default: false
    t.string "new_language_preference"
    t.datetime "consent_given_at"
    t.string "incentive_receipt_method"
    t.boolean "can_be_quoted_for_research", default: false
    t.boolean "can_be_contacted_for_research", default: false
    t.datetime "sent_survey_at"
    t.index ["last_content_id"], name: "index_users_on_last_content_id"
    t.index ["local_authority_id"], name: "index_users_on_local_authority_id"
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

  add_foreign_key "demographic_data", "users"
  add_foreign_key "diary_entries", "users"
  add_foreign_key "interests", "users"
  add_foreign_key "messages", "contents"
  add_foreign_key "users", "contents", column: "last_content_id"
  add_foreign_key "users", "local_authorities"

  create_view "la_specific_dashboards", materialized: true, sql_definition: <<-SQL
      WITH la AS (
           SELECT local_authorities.id,
              local_authorities.name AS la_name
             FROM local_authorities
          ), total_users AS (
           SELECT users.local_authority_id,
              count(users.*) AS total_user_count
             FROM users
            GROUP BY users.local_authority_id
          ), new_users_this_month AS (
           SELECT users.local_authority_id,
              count(users.*) AS new_users_this_month_count
             FROM users
            WHERE ((date_trunc('month'::text, users.created_at))::date >= (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date)
            GROUP BY users.local_authority_id
          ), new_users_this_year AS (
           SELECT users.local_authority_id,
              count(users.*) AS new_users_this_year_count
             FROM users
            WHERE ((date_trunc('year'::text, users.created_at))::date >= (date_trunc('year'::text, (CURRENT_DATE)::timestamp with time zone))::date)
            GROUP BY users.local_authority_id
          ), average_overall_clickthrough_rates AS (
           SELECT users.local_authority_id,
              (((count(messages.clicked_at))::numeric / NULLIF((count(*))::numeric, (0)::numeric)) * (100)::numeric) AS average_overall_clickthrough_rates
             FROM (messages
               JOIN users ON ((messages.user_id = users.id)))
            WHERE (messages.content_id IS NOT NULL)
            GROUP BY users.local_authority_id
          ), average_month_clickthrough_rates AS (
           SELECT users.local_authority_id,
              (((count(messages.clicked_at))::numeric / NULLIF((count(*))::numeric, (0)::numeric)) * (100)::numeric) AS average_this_month_clickthrough_rates
             FROM (messages
               JOIN users ON ((messages.user_id = users.id)))
            WHERE ((messages.content_id IS NOT NULL) AND ((date_trunc('month'::text, messages.created_at))::date >= (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date))
            GROUP BY users.local_authority_id
          )
   SELECT la.la_name,
      total_users.total_user_count,
      new_users_this_month.new_users_this_month_count,
      new_users_this_year.new_users_this_year_count,
      average_overall_clickthrough_rates.average_overall_clickthrough_rates,
      average_month_clickthrough_rates.average_this_month_clickthrough_rates
     FROM (((((la
       LEFT JOIN total_users ON ((la.id = total_users.local_authority_id)))
       LEFT JOIN new_users_this_month ON ((la.id = new_users_this_month.local_authority_id)))
       LEFT JOIN new_users_this_year ON ((la.id = new_users_this_year.local_authority_id)))
       LEFT JOIN average_overall_clickthrough_rates ON ((la.id = average_overall_clickthrough_rates.local_authority_id)))
       LEFT JOIN average_month_clickthrough_rates ON ((la.id = average_month_clickthrough_rates.local_authority_id)));
  SQL
  create_view "all_las_dashboards", materialized: true, sql_definition: <<-SQL
      WITH total_users AS (
           SELECT count(*) AS total_user_count
             FROM users
            WHERE (users.contactable = true)
          ), new_users_this_month AS (
           SELECT count(*) AS new_users_this_month_count
             FROM users
            WHERE (((date_trunc('month'::text, users.created_at))::date >= (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date) AND (users.contactable = true))
          ), new_users_this_year AS (
           SELECT count(*) AS new_users_this_year_count
             FROM users
            WHERE ((users.contactable = true) AND ((date_trunc('year'::text, users.created_at))::date >= (date_trunc('year'::text, (CURRENT_DATE)::timestamp with time zone))::date))
          ), average_overall_clickthrough_rates AS (
           SELECT (((count(messages.clicked_at))::numeric / NULLIF((count(*))::numeric, (0)::numeric)) * (100)::numeric) AS average_overall_clickthrough_rates
             FROM (messages
               JOIN users ON ((messages.user_id = users.id)))
            WHERE ((messages.content_id IS NOT NULL) AND (users.contactable = true))
          ), average_month_clickthrough_rates AS (
           SELECT (((count(messages.clicked_at))::numeric / NULLIF((count(*))::numeric, (0)::numeric)) * (100)::numeric) AS average_this_month_clickthrough_rates
             FROM (messages
               JOIN users ON ((messages.user_id = users.id)))
            WHERE ((messages.content_id IS NOT NULL) AND ((date_trunc('month'::text, messages.created_at))::date >= (date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date) AND (users.contactable = true))
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
      average_month_clickthrough_rates;
  SQL
end
