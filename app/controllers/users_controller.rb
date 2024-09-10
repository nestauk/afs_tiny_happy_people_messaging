class UsersController < ApplicationController
  before_action :authenticate_admin!, only: [:index, :show]

  def index
    @users = User.all
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

      redirect_to root_path, notice: "Thank you for registering an interest, we will be in touch with an update soon."
    else
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone_number, :child_age, :interest_ids)
  end
end
