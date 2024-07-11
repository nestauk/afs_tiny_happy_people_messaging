class InterestsController < ApplicationController
  def new
    @interest = Interest.new
  end

  def create
    @interests = interest_params[:title].compact_blank.map do |title|
      Interest.create(title:)
    end

    if interest_params[:other_title].present?
      @interests << Interest.create(title: interest_params[:other_title])
    end

    redirect_to new_user_path(interest_ids: @interests.map(&:id).join(","))
  end

  private 

  def interest_params
    params.require(:interest).permit(:other_title, title: [])
  end
end

