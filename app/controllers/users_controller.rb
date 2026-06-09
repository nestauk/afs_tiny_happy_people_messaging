class UsersController < ApplicationController
  STEPS = %w[personalisation about_service].freeze
  SIGNUP_CAP = 3000
  SIGNUP_WINDOW_START = Date.new(2026, 5, 13)

  rate_limit to: 10, within: 5.minutes, by: -> { request.ip }, only: :create, with: -> { rate_limit_exceeded }

  skip_before_action :authenticate_admin!
  before_action :set_page_variables, only: [:new, :edit, :thank_you]
  before_action :set_user, only: [:edit, :update, :thank_you]
  after_action :track_action, only: [:edit, :new, :thank_you]

  def new
    @no_padding = true
    @user = User.new
  end

  def create
    redirect_to root_path, notice: "Signups are currently paused. Please check back later." and return if ENV.fetch("SIGN_UP_OPEN", "true") == "false"

    if User.where("created_at > ?", UsersController::SIGNUP_WINDOW_START).count >= UsersController::SIGNUP_CAP
      # This renders in the sign up form which uses turbo so doesn't redirect, so the flash message works.
      return redirect_to root_path, notice: I18n.t("controllers.users.create.notice")
    end

    registration = Registration.new(user_params: user_params, referrer_params: user_referrer_params)

    if registration.submit
      user = registration.user
      token = user.generate_token_for(:profile_token)

      if user.on_waitlist?
        redirect_to thank_you_user_path(user, token: token)
      else
        redirect_to edit_user_path(user, token: token)
      end
    else
      @no_padding = true
      @hide_sidebar = true
      @user = registration.user

      render :new, status: :unprocessable_content
    end
  end

  def edit
    @step = params[:step].presence_in(STEPS) || STEPS.first
  end

  def update
    @step = params[:step].presence_in(STEPS) || STEPS.first
    ahoy.track @step, request.path_parameters

    if @step == "personalisation"
      if @user.update(personalisation_params)
        @user.update(contactable: true) unless @user.contactable?
        redirect_to edit_user_path(@user, token: params[:token], step: "about_service")
      else
        render :edit, status: :unprocessable_content
      end
    elsif @step == "about_service"
      if @user.update(about_service_params)
        SendWelcomeMessageJob.perform_later(@user)
        redirect_to thank_you_user_path(@user, token: params[:token])
      else
        render :edit, status: :unprocessable_content
      end
    end
  end

  def thank_you
    @no_padding = true
    @survey = Survey.find_by(title_en: "Pre-programme survey")

    if @survey
      SurveySend.find_or_create_by(user: @user, survey: @survey) do |ss|
        ss.sent_at = Time.zone.now
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :phone_number, :child_birthday, :language,
      :postcode, :child_name, :terms_agreed, :skip_age_validation
    )
  end

  def user_referrer_params
    params.fetch(:user_referrer, {}).permit(:utm_source, :utm_medium,
      :utm_campaign, :utm_term, :utm_content,
      :gclid)
  end

  def personalisation_params
    params.require(:user).permit(:first_name, :child_name, :hour_preference, :day_preference, :language)
  end

  def about_service_params
    params.require(:user).permit(referral_sources: [])
  end

  def track_action
    ahoy.track request.path_parameters[:action], request.path_parameters.merge(local: I18n.locale)
  end

  def set_page_variables
    @show_footer = true
    @hide_sidebar = true
  end

  def set_user
    @user = User.find_by_token_for(:profile_token, params[:token]) ||
      User.find_by_token_for(:restart_token, params[:token])
    unless @user
      User.report_expired_token(params[:token])
      redirect_to root_path, notice: I18n.t("controllers.users.edit.notice")
    end
  end

  def rate_limit_exceeded
    @user = User.new
    @no_padding = true
    @hide_sidebar = true

    # This renders in the sign up form which uses turbo so doesn't redirect, so the flash message works.
    flash.now[:notice] = I18n.t("controllers.users.rate_limit_exceeded.notice")
    render :new, status: :unprocessable_content
  end
end
