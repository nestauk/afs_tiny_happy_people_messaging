class Admin::AdminsController < ApplicationController
  before_action :set_admin, only: [:edit, :update, :destroy]
  before_action :check_admin_role
  after_action :do_not_track!

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
      redirect_to admin_admins_path, notice: "Admin was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /admins/1
  def update
    if @admin.update(admin_params)
      bypass_sign_in(@admin) if @admin == current_admin

      redirect_to admin_admins_path, notice: "Admin was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @admin.destroy

    redirect_to admin_admins_path, notice: "Admin was successfully deleted."
  end

  private

  def set_admin
    @admin = Admin.find(params[:id])
  end

  def admin_params
    permitted = params.require(:admin).permit(:email, :role)
    current_admin.super_admin? ? permitted : permitted.except(:role)
  end
end
