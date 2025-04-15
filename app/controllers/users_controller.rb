class UsersController < ApplicationController
  STEPS = %w[personalisation about_service].freeze

  rate_limit to: 5, within: 5.minutes, by: -> { request.ip }, only: :create, with: -> { rate_limit_exceeded }

  skip_before_action :authenticate_admin!
  before_action :set_page_variables, only: [:new, :edit, :thank_you]
  before_action :check_token_session, only: [:edit, :update]
  after_action :track_action, only: [:edit, :create, :thank_you]

  def new
    @no_padding = true
    @user = User.new
    set_languages

    ahoy.track "#{request.path_parameters[:action]} - #{params[:q].presence || "no-referrer"}", request.path_parameters
  end

  def create
    redirect_to root_path, notice: "Signups are currently paused. Please check back later." and return if ENV.fetch("SIGN_UP_OPEN", "true") == "false"

    if User.not_finished_content.count == 2001
      return redirect_to root_path, notice: "Thank you for your interest. Due to overwhelming demand, we've reached our maximum signup capacity for now. Please check back in in a few months"
    end

    @user = User.new(user_params)

    @user.terms_agreed_at = Time.zone.now if user_params[:terms_agreed_at] == "1"

    if @user.save
      @user.update_local_authority

      verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
      token = verifier.generate({user_id: @user.id, exp: 15.minutes.from_now.to_i})

      redirect_to edit_user_path(@user, token:)
    else
      @no_padding = true
      @hide_sidebar = true
      set_languages

      render :new, status: :unprocessable_content
    end
  end

  def edit
    @user = User.find(params[:id])
    @step = params[:step].presence_in(STEPS) || STEPS.first
  end

  def update
    @user = User.find(params[:id])
    @step = params[:step].presence_in(STEPS) || STEPS.first
    ahoy.track @step, request.path_parameters

    if @step == "personalisation"
      if @user.update(personalisation_params)
        redirect_to edit_user_path(@user, token: params[:token], step: "about_service")
      else
        render :edit, status: :unprocessable_content
      end
    else
      service_params = about_service_params
      interests = service_params.delete(:interests).to_a.compact_blank

      if @user.update(service_params)
        interests.each { |title| @user.interests.create(title:) }
        @user.is_in_study? ? @user.put_on_waitlist : SendWelcomeMessageJob.perform_now(@user)
        redirect_to thank_you_users_path
      else
        render :edit, status: :unprocessable_content
      end
    end
  end

  def thank_you
    @no_padding = true
  end

  private

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :phone_number, :child_birthday,
      :postcode, :child_name, :terms_agreed_at
    )
  end

  def personalisation_params
    params.require(:user).permit(:child_name, :hour_preference, :day_preference)
  end

  def about_service_params
    params.require(:user).permit(:referral_source, :new_language_preference, interests: [])
  end

  def track_action
    ahoy.track request.path_parameters[:action], request.path_parameters
  end

  def set_page_variables
    @show_footer = true
    @hide_sidebar = true
  end

  def check_token_session
    unless session_token_valid?
      redirect_to root_path, notice: "Your session has expired. Contact info@thp-text.uk if you need further help."
    end
  end

  def session_token_valid?
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
    data = verifier.verify(params[:token])

    Time.zone.at(data["exp"]) > Time.current
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    false
  end

  def set_languages
    @languages = if params[:locale] == "cy"
      [["Cymraeg", "cy"], ["English", "en"]]
    else
      [["English", "en"], ["Cymraeg", "cy"]]
    end
  end

  def rate_limit_exceeded
    @user = User.new
    flash.now[:notice] = "Too many attempts. Try again later."
    render :new, status: :unprocessable_content
  end

  def set_languages
    @languages = if params[:locale] == "cy"
      [["Cymraeg", "cy"], ["English", "en"]]
    else
      [["English", "en"], ["Cymraeg", "cy"]]
    end
  end
end
