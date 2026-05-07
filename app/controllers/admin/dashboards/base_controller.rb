class Admin::Dashboards::BaseController < ApplicationController
  before_action :set_local_authority

  private

  NOCAPS = %w[and of with].freeze

  def set_local_authority
    name = params[:q].split("_").map { |word| NOCAPS.include?(word) ? word : word.capitalize }.join(" ")
    @local_authority = LocalAuthority.find_by(name:)
  end

  def timeframe
    params[:timeframe]
  end

  def timeframe_format
    Dashboards::ChartLabels::FORMATS[timeframe]
  end
end
