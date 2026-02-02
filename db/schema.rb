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

ActiveRecord::Schema[8.1].define(version: 2026_02_02_164415) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "admins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "admin", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.uuid "user_id"
    t.bigint "visit_id"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "browser"
    t.string "device_type"
    t.text "landing_page"
    t.string "os"
    t.text "referrer"
    t.string "referring_domain"
    t.datetime "started_at"
    t.text "user_agent"
    t.uuid "user_id"
    t.string "visit_token"
    t.string "visitor_token"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "auto_responses", force: :cascade do |t|
    t.jsonb "content_adjustment_conditions", default: "{}"
    t.datetime "created_at", null: false
    t.string "response"
    t.string "trigger_phrase", null: false
    t.jsonb "update_content_adjustment", default: "{}"
    t.jsonb "update_user", default: "{}"
    t.datetime "updated_at", null: false
    t.jsonb "user_conditions", default: "{}"
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.datetime "created_at"
    t.string "data_source"
    t.bigint "query_id"
    t.text "statement"
    t.bigint "user_id"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.string "check_type"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "emails"
    t.datetime "last_run_at"
    t.text "message"
    t.bigint "query_id"
    t.string "schedule"
    t.text "slack_channels"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dashboard_id"
    t.integer "position"
    t.bigint "query_id"
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "data_source"
    t.text "description"
    t.string "name"
    t.text "statement"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "content_adjustments", force: :cascade do |t|
    t.datetime "adjusted_at"
    t.datetime "created_at", null: false
    t.string "direction"
    t.boolean "needs_adjustment"
    t.integer "number_down_options"
    t.integer "number_up_options"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_content_adjustments_on_user_id"
  end

  create_table "content_age_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.integer "max_months", null: false
    t.integer "min_months", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contents", force: :cascade do |t|
    t.integer "age_in_months", null: false
    t.datetime "archived_at"
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "group_id"
    t.string "link"
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "position"], name: "index_contents_on_group_id_and_position", unique: true
    t.index ["group_id"], name: "index_contents_on_group_id"
  end

  create_table "demographic_data", force: :cascade do |t|
    t.integer "age"
    t.string "children_ages"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "education"
    t.string "employment_status"
    t.string "ethnicity"
    t.string "gender"
    t.string "household_income"
    t.string "marital_status"
    t.integer "number_of_children"
    t.boolean "receiving_credit"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_demographic_data_on_user_id"
  end

  create_table "diary_entries", force: :cascade do |t|
    t.text "activities_from_previous_weeks"
    t.text "changes_to_make"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.jsonb "days", default: [], array: true
    t.boolean "did_previous_week_activity"
    t.text "enjoyed_least"
    t.text "enjoyed_most"
    t.jsonb "feedback", default: [], array: true
    t.text "feedback_reason"
    t.boolean "first_week"
    t.text "reason_for_not_doing_activity"
    t.jsonb "timings", default: [], array: true
    t.integer "total_time"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "video_message"
    t.index ["user_id"], name: "index_diary_entries_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "language", default: "en", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "interests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_interests_on_user_id"
  end

  create_table "local_authorities", force: :cascade do |t|
    t.string "country"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.text "body"
    t.datetime "clicked_at"
    t.bigint "content_id"
    t.datetime "created_at", null: false
    t.string "link"
    t.datetime "marked_as_seen_at"
    t.string "message_sid"
    t.datetime "sent_at"
    t.string "status"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["content_id"], name: "index_messages_on_content_id"
    t.index ["token"], name: "index_messages_on_token", unique: true
  end

  create_table "research_study_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "last_four_digits_phone_number", null: false
    t.string "postcode", null: false
    t.datetime "updated_at", null: false
    t.index ["last_four_digits_phone_number", "postcode"], name: "idx_on_last_four_digits_phone_number_postcode_9947703d95", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "asked_for_feedback", default: false
    t.boolean "can_be_contacted_for_research", default: false
    t.boolean "can_be_quoted_for_research", default: false
    t.date "child_birthday", null: false
    t.string "child_name"
    t.datetime "consent_given_at"
    t.boolean "contactable", default: true
    t.datetime "created_at", null: false
    t.integer "day_preference", default: 1, null: false
    t.boolean "diary_study", default: false
    t.string "email"
    t.string "first_name", null: false
    t.string "hour_preference"
    t.string "incentive_receipt_method"
    t.string "language", default: "en", null: false
    t.bigint "last_content_id"
    t.string "last_name", null: false
    t.bigint "local_authority_id"
    t.string "new_language_preference"
    t.datetime "nudged_at"
    t.string "phone_number", null: false
    t.string "postcode", null: false
    t.string "referral_source"
    t.datetime "restart_at"
    t.datetime "sent_survey_at"
    t.datetime "terms_agreed_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid"
    t.index ["last_content_id"], name: "index_users_on_last_content_id"
    t.index ["local_authority_id"], name: "index_users_on_local_authority_id"
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

  add_foreign_key "content_adjustments", "users"
  add_foreign_key "demographic_data", "users"
  add_foreign_key "diary_entries", "users"
  add_foreign_key "interests", "users"
  add_foreign_key "messages", "contents"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "users", "contents", column: "last_content_id"
  add_foreign_key "users", "local_authorities"

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
end
