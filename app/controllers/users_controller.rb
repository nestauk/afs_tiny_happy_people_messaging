class UsersController < ApplicationController
  skip_before_action :authenticate_admin!, except: [:index, :show, :dashboard]
  before_action :show_footer, only: [:new, :edit, :thank_you]
  before_action :check_admin_role, only: [:index, :dashboard, :show]
  before_action :check_token_session, only: [:edit, :update]
  after_action :track_action, only: [:edit, :create, :thank_you]

  def index
    if params[:letter].present?
      @letter = params[:letter].upcase
      @current_users = User.contactable.where("last_name LIKE ?", "#{@letter}%").order(:last_name, :first_name).page(params[:page]).per(25)
    else
      @current_users = User.contactable.order(:last_name, :first_name).page(params[:page]).per(25)
    end

    @opted_out_users = User.opted_out.order(:last_name, :first_name).page(params[:page]).per(25)
  end

  def dashboard
    @messages = Message.where(status: "received", marked_as_seen_at: nil)
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @no_padding = true
    @user = User.new
    set_languages

    ahoy.track "#{request.path_parameters[:action]} - #{params[:q].blank? ? "no-referrer" : params[:q]}", request.path_parameters
  end

  def create
    if User.not_finished_content.count == 2001
      return redirect_to root_path, notice: "Thank you for your interest. Due to overwhelming demand, we've reached our maximum signup capacity for now. Please check back in in a few months"
    end

    @user = User.new(user_params)

    @user.terms_agreed_at = Time.now if user_params[:terms_agreed_at] == "1"

    if @user.save
      @user.update_local_authority

      verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
      token = verifier.generate({user_id: @user.id, exp: 15.minutes.from_now.to_i})

      redirect_to edit_user_path(@user, token:)
    else
      @no_padding = true
      set_languages
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    user = User.find(params[:id])
    @user = UserProfile.new(user, params)
  end

  def update
    user = User.find(params[:id])
    @user = UserProfile.new(user, params)
    ahoy.track @user.stage, request.path_parameters

    if @user.save
      SendWelcomeMessageJob.perform_now(@user.user)

      redirect_to thank_you_users_path
    else
      check_token_session

      render :edit, status: :unprocessable_entity
    end
  end

  def thank_you
    @no_padding = true
  end

  private

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :phone_number, :child_birthday, :email, :id, :new_language_preference,
      :postcode, :hour_preference, :day_preference, :referral_source, :child_name, :language,
      :terms_agreed_at, interests: []
    )
  end

  def track_action
    ahoy.track request.path_parameters[:action], request.path_parameters
  end

  def show_footer
    @show_footer = true
  end

  def check_admin_role
    redirect_to root_path unless current_admin.role == "admin"
  end

  def check_token_session
    if !session_token_valid?
      redirect_to root_path, notice: "Your session has expired. Contact info@thp-text.uk if you need further help."
    end
  end

  def session_token_valid?
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
    data = verifier.verify(params[:token])

    Time.at(data["exp"]) > Time.current
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    false
  end

  def set_languages
    @languages = if params[:locale] == "cy"
      [['Cymraeg', 'cy'], ['English', 'en']]
    else
      [['English', 'en'], ['Cymraeg', 'cy']]
    end
  end
end
