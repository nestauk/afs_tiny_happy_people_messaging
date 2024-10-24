class ContentsController < ApplicationController
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
    @content = Content.find(params[:id])
  end

  def update
    @content = Content.find(params[:id])

    if @content.update(content_params)
      redirect_to group_path(@content.group), notice: "Content updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_position
    @content = Content.find(params[:id])
    @content.update(position: params[:position])
    head :no_content
  end

  def destroy
    @content = Content.find(params[:id])
    @content.destroy
    redirect_to group_path(@content.group), notice: "Content deleted"
  end

  private

  def content_params
    params.require(:content).permit(:body, :link, :position, :welcome_message)
  end
end
