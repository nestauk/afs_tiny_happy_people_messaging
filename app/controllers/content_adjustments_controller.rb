class ContentAdjustmentsController < ApplicationController
  before_action :authenticate_admin!
  before_action :check_admin_role

  def index
    @content_adjustment_users = User.needs_assessment.includes([:latest_adjustment])
  end

  def automated
    @content_adjustments = ContentAdjustment.complete
    render :index
  end

  def incomplete
    @content_adjustments = ContentAdjustment.incomplete
    render :index
  end
end
