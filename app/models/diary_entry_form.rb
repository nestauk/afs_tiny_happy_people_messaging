class DiaryEntryForm
  extend ActiveModel::Naming
  extend ActiveModel::Translation
  include ActiveModel::Conversion

  STAGES = %w[welcome this_week previous_week feedback]

  DIARY_ENTRY_PARAMS = [
    :total_time, :did_previous_week_activity, :first_week, :activities_from_previous_weeks,
    :feedback_reason, :reason_for_not_doing_activity, :enjoyed_most, :enjoyed_least, :changes_to_make,
    days: [], timings: [], feedback: []
  ]
  CONSENT_PARAMS = [:questions, :info_sheet, :confidential, :storage, :withdraw]
  PERMITTED_PARAMS = [:stage, :move_back, :move_next, :commit, diary_entry_form: DIARY_ENTRY_PARAMS]

  attr_reader :params, :errors, :user, :session

  def initialize(user, params, session)
    @params = params.permit(*PERMITTED_PARAMS)
    @errors = ActiveModel::Errors.new(self)
    @session = session
    @user = user
  end

  def read_attribute_for_validation(attribute)
    public_send(attribute)
  end

  def to_partial_path
    "diary_entries/new/#{stage}_stage"
  end

  def persisted?
    @user.persisted?
  end

  def stage
    @stage ||= stage_param.in?(STAGES) ? stage_param : STAGES.first
  end

  def save
    if moving_backwards?
      @stage = previous_stage and return false
    end

    unless valid?
      return false
    end

    if done?
      form = @user.diary_entries.new(diary_entry_form_params.merge(completed_at: Time.zone.now))

      form.assign_attributes(
        days: session[:days],
        timings: session[:timings],
        feedback: session[:feedback],
        first_week: did_previous_week_activity == "first_week",
        did_previous_week_activity: (did_previous_week_activity == "first_week") ? nil : did_previous_week_activity
      )

      if form.save
        true
      else
        @stage = "this_week"
        false
      end
    else
      @stage = next_stage and return false
    end
  end

  def days
    diary_entry_form_params[:days] || session[:days] || []
  end

  def timings
    diary_entry_form_params[:timings] || session[:timings] || []
  end

  def total_time
    diary_entry_form_params[:total_time].to_s.strip
  end

  def did_previous_week_activity
    diary_entry_form_params[:did_previous_week_activity].to_s.strip
  end

  def activities_from_previous_weeks
    diary_entry_form_params[:activities_from_previous_weeks].to_s.strip
  end

  def feedback
    diary_entry_form_params[:feedback] || session[:feedback] || []
  end

  def feedback_reason
    diary_entry_form_params[:feedback_reason].to_s.strip
  end

  def reason_for_not_doing_activity
    diary_entry_form_params[:reason_for_not_doing_activity].to_s.strip
  end

  def enjoyed_most
    diary_entry_form_params[:enjoyed_most].to_s.strip
  end

  def enjoyed_least
    diary_entry_form_params[:enjoyed_least].to_s.strip
  end

  def changes_to_make
    diary_entry_form_params[:changes_to_make].to_s.strip
  end

  private

  def stage_param
    @stage_param ||= params[:stage].to_s
  end

  def diary_entry_form_params
    params[:diary_entry_form] || {}
  end

  def moving_backwards?
    params.key?(:move_back)
  end

  def saving_draft?
    params.key?(:save_draft)
  end

  def stage_index
    STAGES.index(stage)
  end

  def previous_stage
    STAGES[[stage_index - 1, 0].max]
  end

  def next_stage
    STAGES[[stage_index + 1, 3].min]
  end

  def validate_diary_study
    if errors.any?
      @stage = stage
    end
  end

  def validate
    validate_diary_study
  end

  def valid?
    errors.clear
    validate
    errors.empty?
  end

  def done?
    stage == "feedback"
  end
end
