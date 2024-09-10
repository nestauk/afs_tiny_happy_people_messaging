class MessagesController < ApplicationController
  def index
    @messages = Message.all
  end

  def ping
    body = params['Body']

    Message.create(user: User.last, body:)
  end

  def new
    @user = User.find(params[:user_id])
    @message = Message.new
  end

  def create
    @message = Message.new(message_params)

    if @message.save
      Delayed::Job.enqueue SendMesssageJob.new(user)

      redirect_to user_messages_path(@message.user), notice: "Message sent!"
    else
      render :new
    end
  end

  private

  def message_params
    params.require(:message).permit(:user_id, :body)
  end
end
