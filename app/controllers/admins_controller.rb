class AdminsController < ApplicationController
  before_action :set_admin, only: [:edit, :update]
  before_action :check_admin_role

  # GET /admins
  def index
    @admins = Admin.all
  end

  # GET /admins/new
  def new
    @admin = Admin.new
  end

  # GET /admins/1/edit
  def edit
  end

  # POST /admins
  def create
    @admin = Admin.new(admin_params)

    if @admin.save
      redirect_to admins_path, notice: "Admin was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admins/1
  def update
    if @admin.update(admin_params)
      bypass_sign_in(@admin) if @admin == current_admin

      redirect_to admins_path, notice: "Admin was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_admin
    @admin = Admin.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def admin_params
    params.require(:admin).permit(:email)
  end

  def check_admin_role
    redirect_to root_path unless current_admin.role == "admin"
  end
end
