class Admin::UsersController < ApplicationController
  before_action :check_admin_role

  def index
    @users = User.where("phone_number ILIKE ?", "%#{params[:phone_number]}%")
      .where(params[:finished].present? ? {last_content_id: Content.order(:position).last&.id} : {})
      .where(params[:opted_out].present? ? {contactable: false} : {})
      .order(:first_name)

    @current_users = @users.page(params[:page]).per(25)
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
