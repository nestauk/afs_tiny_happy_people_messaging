class UsersController < ApplicationController
  skip_before_action :authenticate_admin!, except: [:index, :show, :dashboard]

  def index
    @users = User.all
  end

  def dashboard
    @messages = Message.where(status: "received")
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    @user.terms_agreed_at = Time.now if user_params[:terms_agreed_at] == "1"

    if @user.save
      SendWelcomeMessageJob.perform_now(@user)

      redirect_to thank_you_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :phone_number, :child_birthday,
      :postcode, :timing, :community_sign_up, :family_support, :terms_agreed_at
    )
  end
end
