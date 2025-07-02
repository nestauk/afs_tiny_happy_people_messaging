class ContentsController < ApplicationController
  before_action :check_admin_role
  before_action :set_content, except: %i[new create]

  def new
    @group = Group.find_by(id: params[:group_id])
    @content = @group.contents.new
  end

  def create
    @group = Group.find_by(id: params[:group_id])
    @content = @group.contents.new(content_params)

    if @content.save
      redirect_to group_path(@content.group), notice: "Content for message was successfully created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @content.update(content_params)
      redirect_to group_path(@content.group), notice: "Content updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_position
    @content.update(position: params[:position])
    head :no_content
  end

  def archive
    if @content.update(archived_at: Time.now)
      redirect_to group_path(@content.group), notice: "Content archived"
    else
      render group_path(@content.group), status: :unprocessable_entity
    end
  end

  private

  def set_content
    @content = Content.find(params[:id])
  end

  def content_params
    params.require(:content).permit(:body, :link, :position, :age_in_months)
  end
end
