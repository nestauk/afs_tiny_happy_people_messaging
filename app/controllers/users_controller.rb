class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params.except(:interest_ids))

    if @user.save
      user_params[:interest_ids].split(",").each do |interest_id|
        @user.interests << Interest.find(interest_id)
      end

      redirect_to user_path(@user)
    else
      render :new
    end
  end

  def show
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone_number, :child_age, :interest_ids)
  end
end
