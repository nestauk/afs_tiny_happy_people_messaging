Skadi.configure do |config|
  config.user_model = "Admin"
  config.user_controller_method = :current_admin

  config.dashboard_view_controller_method = :admin_role?
  config.dashboard_edit_controller_method = :admin_role?
  config.dashboard_dangerously_use_sql_controller_method = :admin_role?

  config.use_anonymity_sets = true

  config.count_bots = true

  config.dashboard_custom_event_fields = {}

  config.dashboard_custom_schema = {}
end
