class UserProfile
  extend ActiveModel::Naming
  extend ActiveModel::Translation
  include ActiveModel::Conversion

  STAGES = %w[personalisation about_service diary_study]

  USER_PARAMS = [
    :email, :hour_preference, :day_preference, :referral_source, :id, :new_language_preference,
    :diary_study, :diary_study_contact_method, :child_name, interests: []
  ]
  PERMITTED_PARAMS = [:stage, :move_back, :move_next, user_profile: USER_PARAMS]

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
        if interests.any?
          interests.each do |title|
            interest = Interest.find_or_create_by(title:)
            @user.interests << interest
          end
        end
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

  def email
    user_profile_params[:email].to_s.strip
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

  def diary_study
    user_profile_params[:diary_study] || "0"
  end

  def diary_study_contact_method
    user_profile_params[:diary_study_contact_method].to_s.strip
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
    STAGES[[stage_index + 1, 2].min]
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
    stage == if diary_study == "1"
      "diary_study"
    else
      "about_service"
    end
  end
end
