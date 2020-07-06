require 'test_helper'

class VideoTest < ActiveSupport::TestCase
  let (:video_data) {
    {
      "title": "Hidden Figures",
      "overview": "Some text",
      "release_date": "1960-06-16",
      "inventory": 8
    }
  }

  before do
    @video = Video.new(video_data)
  end

  describe "Constructor" do
    it "Can be created" do
      Video.create!(video_data)
    end

    it "Has rentals" do
      expect(@video).must_respond_to :rentals
    end

    it "Has customers" do
      expect(@video).must_respond_to :customers
    end
  end

  describe "available_inventory" do
    it "Matches inventory if the video isn't checked out" do
      # Make sure no videos are checked out
      Rental.destroy_all
      Video.all.each do |video|
        expect(video.available_inventory()).must_equal video.inventory
      end
    end

    it "Decreases when a video is checked out" do
      Rental.destroy_all

      video = videos(:one)
      before_ai = video.available_inventory

      Rental.create!(
        customer: customers(:one),
        video: video,
        due_date: Date.today + 7,
        returned: false
      )

      video.reload
      after_ai = video.available_inventory
      expect(after_ai).must_equal before_ai - 1
    end

    it "Increases when a video is checked in" do
      Rental.destroy_all

      video = videos(:one)

      rental =Rental.create!(
        customer: customers(:one),
        video: video,
        due_date: Date.today + 7,
        returned: false
      )

      video.reload
      before_ai = video.available_inventory

      rental.returned = true
      rental.save!

      video.reload
      after_ai = video.available_inventory
      expect(after_ai).must_equal before_ai + 1
    end
  end
end
