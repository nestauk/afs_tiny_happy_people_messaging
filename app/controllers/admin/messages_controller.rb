class Admin::MessagesController < ApplicationController
  before_action :check_admin_role, only: [:index, :new, :create]

  def index
    @messages = Message.all
  end

  def new
    @user = User.find(params[:user_id])
    @message = Message.new
  end

  def create
    @message = Message.new(message_params)

    if @message.save
      SendCustomMessageJob.perform_later(@message)

      redirect_to admin_user_path(@message.user), notice: "Message sent!"
    else
      render :new
    end
  end

  def update
    @message = Message.find(params[:id])
    @message.assign_attributes(marked_as_seen_at: Time.zone.now) if params[:seen] == "true"

    if @message.save
      redirect_to dashboard_admin_users_path, notice: "Message marked as seen"
    else
      redirect_to dashboard_admin_users_path, alert: "Message not updated"
    end
  end

  private

  def message_params
    params.require(:message).permit(:user_id, :body)
  end
end
