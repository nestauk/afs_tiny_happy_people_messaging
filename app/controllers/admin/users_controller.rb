class Admin::UsersController < ApplicationController
  before_action :check_admin_role, only: [:index, :dashboard, :show]

  def index
    users = if params[:opted_out].present?
      User.opted_out
    else
      User.contactable
    end

    if params[:letter].present?
      @letter = params[:letter].upcase
      @current_users = users.where("last_name LIKE ?", "#{@letter}%").order(:last_name, :first_name).page(params[:page]).per(25)
    else
      @current_users = users.order(:last_name, :first_name).page(params[:page]).per(25)
    end
  end

  def dashboard
    @messages = Message.where(status: "received", marked_as_seen_at: nil)
  end

  def show
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User updated successfully."
    else
      render :show
    end
  end

  private

  def user_params
    params.require(:user).permit(:contactable)
  end
end
