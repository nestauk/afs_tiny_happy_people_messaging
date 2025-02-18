class UsersController < ApplicationController
  skip_before_action :authenticate_admin!, except: [:index, :show, :dashboard]
  before_action :show_footer, only: [:new, :edit, :thank_you]
  before_action :check_admin_role, only: [:index, :dashboard, :show]
  after_action :track_action, only: [:edit, :create, :thank_you]

  def index
    @users = User.all
  end

  def dashboard
    @messages = Message.where(status: "received")
  end

  def show
    @user = User.find_by(uuid: params[:uuid])
  end

  def new
    @no_padding = true
    @user = User.new

    ahoy.track "#{request.path_parameters[:action]} - #{params[:q].blank? ? "no-referrer" : params[:q]}", request.path_parameters
  end

  def create
    @user = User.new(user_params)

    @user.terms_agreed_at = Time.now if user_params[:terms_agreed_at] == "1"

    if @user.save
      @user.update_local_authority

      redirect_to edit_user_path(@user.uuid)
    else
      @no_padding = true
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    user = User.find_by(uuid: params[:uuid])
    @user = UserProfile.new(user, params)
  end

  def update
    user = User.find_by(uuid: params[:uuid])
    @user = UserProfile.new(user, params)
    ahoy.track @user.stage, request.path_parameters

    if @user.save
      if @user.user.consent_given_at.present?
        redirect_to new_user_demographic_datum_path(@user.user.uuid)
      else
        SendWelcomeMessageJob.perform_now(@user.user)

        redirect_to thank_you_user_path(@user.user.uuid)
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def thank_you
    @no_padding = true
    @user = User.find_by(uuid: params[:uuid])
  end

  private

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :phone_number, :child_birthday, :email, :id, :new_language_preference,
      :postcode, :hour_preference, :day_preference, :referral_source, :child_name, :consent,
      :can_be_quoted_for_research, :can_be_contacted_for_research,
      :terms_agreed_at, :diary_study, incentive_receipt_method: [], interests: []
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
end
