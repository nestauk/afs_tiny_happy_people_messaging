class ContentAdjustmentsController < ApplicationController
  before_action :authenticate_admin!
  before_action :check_admin_role

  def index
    @content_adjustment_users = User.needs_assessment.includes([:latest_adjustment])
  end

  def automated
    @content_adjustments = ContentAdjustment.select('DISTINCT ON (user_id) *').where.not(adjusted_at: nil).order('user_id, created_at DESC')
    render :index
  end

  def incomplete
    @content_adjustments = ContentAdjustment.select('DISTINCT ON (user_id) *')
      .where("adjusted_at IS NULL AND needs_adjustment = 'true' AND (direction != 'not_sure' OR direction IS NULL)")
      .order('user_id, created_at DESC')
    render :index
  end
end
