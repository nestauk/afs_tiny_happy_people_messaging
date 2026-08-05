class Admin::BroadcastsController < ApplicationController
  before_action :check_admin_role

  def index
    @broadcasts = Broadcast.order(sent_at: :desc).includes(:admin)
  end

  def new
    @broadcast = Broadcast.new
  end

  def create
    @broadcast = Broadcast.new(broadcast_params)
    @broadcast.admin = current_admin
    @broadcast.save_and_send!

    redirect_to admin_broadcasts_path, notice: 'Bulk message created successfully.'
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def show
    @broadcast = Broadcast.find(params[:id])
  end

  private

  def broadcast_params
    params.require(:broadcast).permit(:body_en, :body_cy, :survey_id, :message_threshold, user_groups: [])
  end
end
