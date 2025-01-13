class UsersController < ApplicationController
  skip_before_action :authenticate_admin!, except: [:index, :show, :dashboard]

  def index
    @users = User.all
  end

  def dashboard
    @messages = Message.where(status: "received")
  end

  def show
    @user = User.find(params[:uuid])
  end

  def new
    @user = User.new
    Page.find_or_create_by(name: "users/new").clicks.create if Rails.env.production?
  end

  def create
    @user = User.new(user_params)

    @user.terms_agreed_at = Time.now if user_params[:terms_agreed_at] == "1"

    if @user.save
      @user.update_local_authority

      redirect_to edit_user_path(@user.uuid)
    else
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

    if @user.save
      SendWelcomeMessageJob.perform_now(@user.user)

      redirect_to thank_you_user_path(@user.user.uuid)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def thank_you
    @user = User.find_by(uuid: params[:uuid])
  end

  private

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :phone_number, :child_birthday, :email, :id,
      :postcode, :hour_preference, :day_preference, :referral_source, :child_name,
      :diary_study_contact_method, :terms_agreed_at, :diary_study, interests: []
    )
  end
end
