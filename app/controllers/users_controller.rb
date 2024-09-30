class UsersController < ApplicationController
  before_action :authenticate_admin!, only: [:index, :show, :dashboard]

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
    @user = User.new(user_params.except(:interest_ids))

    if @user.save
      user_params[:interest_ids].split(",").each do |interest_id|
        @user.interests << Interest.find(interest_id)
      end

      SendWelcomeMessageJob.perform_now(@user)

      redirect_to root_path, notice: "You have signed up. Your first text will be sent soon."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :phone_number, :child_birthday, :interest_ids,
      :postcode, :timing, :community_sign_up, :family_support, :terms_agreed_at
    )
  end
end
