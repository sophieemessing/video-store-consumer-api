class VideosController < ApplicationController
  before_action :require_video, only: [:show]

  def index
    if params[:query]
      data = VideoWrapper.search(params[:query])
    else
      data = Video.all
    end

    render status: :ok, json: data
  end

  def show
    render(
      status: :ok,
      json: @video.as_json(
        only: [:title, :overview, :release_date, :inventory],
        methods: [:available_inventory]
        )
      )
  end

  def create
      @video = Video.new
      @video.title = params[:title]
      @video.overview = params[:overview]
      @video.release_date = params[:release_date]
      @video.image_url = "https://image.tmdb.org/t/p/w185" + params[:poster_path]
      @video.external_id = params[:id]
      @video.inventory = 5
      @video.save
      
      render(
      status: :ok,
      json: @video.as_json(
        only: [:title, :overview, :release_date, :image_url, :external_id, :inventory],
        methods: [:available_inventory]
        )
      )
      
    end

  private

  def require_video
    @video = Video.find_by(title: params[:title])
    unless @video
      render status: :not_found, json: { errors: { title: ["No video with title #{params["title"]}"] } }
    end
  end
end
