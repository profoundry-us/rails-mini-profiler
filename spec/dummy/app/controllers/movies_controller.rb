# frozen_string_literal: true

class MoviesController < ApplicationController
  before_action :set_movie, only: %i[show edit update destroy]

  def index
    # Exercise cache and job instrumentation so the profiler's cache/job tracers have real events to record.
    @movie_count = Rails.cache.fetch('movies/count', expires_in: 1.minute) { Movie.count }
    MovieSweepJob.perform_later
    @movies = Movie.all
  end

  def show; end

  def new
    @movie = Movie.new
  end

  def edit; end

  def create
    @movie = Movie.new(movie_params)

    if @movie.save
      redirect_to @movie, notice: 'Movie was successfully created.'
    else
      render :new
    end
  end

  def update
    if @movie.update(movie_params)
      redirect_to @movie, notice: 'Movie was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @movie.destroy
    redirect_to movies_url, notice: 'Movie was successfully destroyed.'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_movie
    @movie = Movie.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def movie_params
    params.require(:movie).permit(:title, :imdb_id, :popularity, :budget, :revenue, :runtime, :release_date)
  end
end
