class Admin::AutoResponsesController < ApplicationController
  before_action :check_admin_role

  def index
    @auto_responses = AutoResponse.all
  end

  def edit
    @auto_response = AutoResponse.find(params[:id])
  end

  def update
    @auto_response = AutoResponse.find(params[:id])

    if @auto_response.update(auto_response_params)
      redirect_to admin_auto_responses_path, notice: "Auto response updated successfully"
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def auto_response_params
    params.require(:auto_response).permit(:response)
  end
end
