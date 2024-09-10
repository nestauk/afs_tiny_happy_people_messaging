class ContentsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @contents = Content.all
  end

  def new
    @content = Content.new
  end

  def create
    @content = Content.new(content_params)

    if @content.save
      redirect_to contents_path, notice: "Content created!"
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
      redirect_to contents_path, notice: "Content updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def content_params
    params.require(:content).permit(:body, :lower_age, :upper_age)
  end
end
