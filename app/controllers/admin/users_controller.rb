class Admin::UsersController < ApplicationController
  before_action :check_admin_role
  before_action :set_user, only: [:show, :edit, :update]

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
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User updated successfully."
    elsif user_params.key?(:content_in_months)
      render :edit, status: :unprocessable_content
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.require(:user).permit(:contactable, :content_in_months)
  end

  def set_user
    @user = User.find(params[:id])
  end
end
