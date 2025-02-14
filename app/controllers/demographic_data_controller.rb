class DemographicDataController < ApplicationController
  skip_before_action :authenticate_admin!
  before_action :set_user

  def new
    @demographic_data = DemographicData.new
  end

  def create
    @demographic_data = DemographicData.new(demographic_data_params)

    if @demographic_data.save
      SendWelcomeMessageJob.perform_now(@user)

      redirect_to thank_you_user_path(@user.uuid)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find_by(uuid: params[:user_uuid])
  end

  def demographic_data_params
    params.require(:demographic_data).permit(
      :gender,
      :age,
      :number_of_children,
      :children_ages,
      :country,
      :ethnicity,
      :education,
      :marital_status,
      :employment_status,
      :household_income,
      :receiving_credit,
      :user_id
    )
  end
end
