require 'test_helper'

class CustomerTest < ActiveSupport::TestCase
  let (:customer_data) {
    {
      "name": "Ada Testington III",
      "registered_at": "Wed, 29 Apr 2015 07:54:14 -0700",
      "address": "12345 Ada Ave E",
      "city": "Seattle",
      "state": "WA",
      "postal_code": "98107",
      "phone": "(123) 456-7890",
      "account_credit": 13.15
    }
  }

  before do
    @customer = Customer.create!(customer_data)
  end

  describe "Constructor" do
    it "Can be created" do
      Customer.create!(customer_data)
    end

    it "Has rentals" do
      expect(@customer).must_respond_to :rentals
    end

    it "Has videos" do
      expect(@customer).must_respond_to :videos
    end
  end

  describe "videos_checked_out_count" do
    it "Should exist" do
      expect(@customer).must_respond_to :videos_checked_out_count
    end

    it "Returns 0 if no rentals" do
      # Burn the world
      Rental.destroy_all

      @customer.reload
      expect(@customer.videos_checked_out_count).must_equal 0
    end

    it "Returns the number of videos checked out" do
      Rental.destroy_all

      Rental.create!(
        customer: @customer,
        video: videos(:one),
        due_date: Date.today + 7,
        returned: false
      )
      Rental.create!(
        customer: @customer,
        video: videos(:two),
        due_date: Date.today + 7,
        returned: false
      )

      @customer.reload
      expect(@customer.videos_checked_out_count).must_equal 2
    end

    it "Ignores returned videos" do
      Rental.destroy_all

      Rental.create!(
        customer: @customer,
        video: videos(:one),
        due_date: Date.today + 7,
        returned: true
      )

      @customer.reload
      expect(@customer.videos_checked_out_count).must_equal 0
    end
  end
end
