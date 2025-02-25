class UserProfile
  extend ActiveModel::Naming
  extend ActiveModel::Translation
  include ActiveModel::Conversion

  STAGES = %w[personalisation about_service]

  USER_PARAMS = [
    :hour_preference, :day_preference, :referral_source, :id, :new_language_preference,
    :child_name, interests: []
  ]
  PERMITTED_PARAMS = [:stage, :move_back, :move_next, :commit, user_profile: USER_PARAMS]

  attr_reader :params, :errors, :user

  def initialize(user, params)
    @params = params.permit(*PERMITTED_PARAMS)
    @errors = ActiveModel::Errors.new(self)
    @user = user
  end

  def read_attribute_for_validation(attribute)
    public_send(attribute)
  end

  def to_partial_path
    "users/edit/#{stage}_stage"
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

    if @user.update(user_profile_params.except(:interests))
      if stage == "about_service"
        interests = user_profile_params[:interests].compact_blank
        create_interests if interests.any?
      end

      if done?
        true
      else
        @stage = next_stage and return false
      end
    else
      false
    end
  end

  def child_name
    user_profile_params[:child_name].to_s.strip
  end

  def hour_preference
    preference = user_profile_params[:hour_preference].to_s.strip

    preference.blank? ? "no_preference" : preference
  end

  def day_preference
    preference = user_profile_params[:day_preference].to_s.strip

    preference.blank? ? 2 : preference
  end

  def referral_source
    user_profile_params[:referral_source].to_s.strip
  end

  def interests
    user_profile_params[:interests] || []
  end

  def new_language_preference
    user_profile_params[:new_language_preference].to_s.strip
  end

  private

  def stage_param
    @stage_param ||= params[:stage].to_s
  end

  def user_profile_params
    params[:user_profile] || {}
  end

  def moving_backwards?
    params.key?(:move_back)
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

  def validate_user
    if errors.any?
      @stage = stage
    end
  end

  def validate
    validate_user
  end

  def valid?
    errors.clear
    validate
    errors.empty?
  end

  def done?
    stage == "about_service"
  end

  def create_interests
    interests.each do |title|
      interest = Interest.find_or_create_by(title:)
      @user.interests << interest
    end
  end
end
