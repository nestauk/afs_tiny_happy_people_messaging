class ContentAdjustmentsController < ApplicationController
  before_action :authenticate_admin!
  before_action :check_admin_role
  before_action :set_content_adjustment, only: [:show, :edit, :update]
  before_action :set_user, only: [:show, :edit, :update]

  def index
    @users = User.needs_adjustment_assessment.includes([:latest_adjustment])
  end

  def automated
    @users = User.completed_adjustment_assessment
    render :index
  end

  def incomplete
    @users = User.incomplete_adjustment_assessment
    render :index
  end

  def show
  end

  def edit
  end

  def update
    content = Content.where(age_in_months: params[:content_adjustment][:content_age]).min_by(&:position)

    if @user.update(last_content_id: content.id) && @content_adjustment.update(adjusted_at: Time.current, needs_adjustment: false)
      message = Message.build(
        user: @user,
        body: "We've updated your content to match your requirements. Let us know if it still isn't appropriate by texting 'Adjust', we'll also check back in in a few weeks."
      )
      SendCustomMessageJob.perform_later(message) if message.save

      redirect_to content_adjustment_path(@content_adjustment), notice: "User's content has been updated."
    else
      render :edit
    end
  end

  private

  def set_content_adjustment
    @content_adjustment = ContentAdjustment.find(params[:id])
  end

  def set_user
    @user = @content_adjustment.user
  end
end
