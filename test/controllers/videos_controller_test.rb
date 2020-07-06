require 'test_helper'

class VideosControllerTest < ActionDispatch::IntegrationTest
  describe "index" do
    it "returns a JSON array" do
      get videos_url
      assert_response :success
      @response.headers['Content-Type'].must_include 'json'

      # Attempt to parse
      data = JSON.parse @response.body
      data.must_be_kind_of Array
    end

    it "should return many video fields" do
      get videos_url
      assert_response :success

      data = JSON.parse @response.body
      data.each do |video|
        video.must_include "title"
        video.must_include "release_date"
      end
    end

    it "returns all videos when no query params are given" do
      get videos_url
      assert_response :success

      data = JSON.parse @response.body
      data.length.must_equal Video.count

      expected_names = {}
      Video.all.each do |video|
        expected_names[video["title"]] = false
      end

      data.each do |video|
        expected_names[video["title"]].must_equal false, "Got back duplicate video #{video["title"]}"
        expected_names[video["title"]] = true
      end
    end
  end

  describe "show" do
    it "Returns a JSON object" do
      get video_url(title: videos(:one).title)
      assert_response :success
      @response.headers['Content-Type'].must_include 'json'

      # Attempt to parse
      data = JSON.parse @response.body
      data.must_be_kind_of Hash
    end

    it "Returns expected fields" do
      get video_url(title: videos(:one).title)
      assert_response :success

      video = JSON.parse @response.body
      video.must_include "title"
      video.must_include "overview"
      video.must_include "release_date"
      video.must_include "inventory"
      video.must_include "available_inventory"
    end

    it "Returns an error when the video doesn't exist" do
      get video_url(title: "does_not_exist")
      assert_response :not_found

      data = JSON.parse @response.body
      data.must_include "errors"
      data["errors"].must_include "title"

    end
  end
end
