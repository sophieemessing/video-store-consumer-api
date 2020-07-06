class RenameMoviesToVideos < ActiveRecord::Migration[6.0]
  def change
    rename_table :movies, :videos
    rename_column :rentals, :movie_id, :video_id
  end
end
