class GroupsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @groups = Group.order(:age_in_months)
  end

  def show
    @group = Group.find_by(id: params[:id])
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)

    if @group.save
      redirect_to groups_path, notice: "Content group successfully created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @group = Group.find(params[:id])
  end

  def update
    @group = Group.find(params[:id])

    if @group.update(group_params)
      redirect_to groups_path, notice: "Content group updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def group_params
    params.require(:group).permit(:name, :age_in_months)
  end
end
