class InterestsController < ApplicationController
  def new
    @interest = Interest.new
  end

  def create
    array = interest_params[:title].compact_blank.map { |title| {title:} }

    array << {title: interest_params[:other_title]} if interest_params[:other_title].present?

    @interests = Interest.create(array)

    redirect_to new_user_path(interest_ids: @interests.map(&:id).join(","))
  end

  private

  def interest_params
    params.require(:interest).permit(:other_title, title: [])
  end
end
