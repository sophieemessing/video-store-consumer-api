require 'test_helper'

class RentalsControllerTest < ActionDispatch::IntegrationTest
  describe "check-out" do
    it "associates a movie with a customer" do
      movie = movies(:one)
      customer = customers(:two)

      post check_out_path(title: movie.title), params: {
        customer_id: customer.id,
        due_date: Date.today + 1
      }
      must_respond_with :success

      # Reload from DB
      Movie.find(movie.id).customers.must_include Customer.find(customer.id)
    end

    it "sets the checkout_date to today" do
      movie = movies(:one)
      customer = customers(:two)

      post check_out_path(title: movie.title), params: {
        customer_id: customer.id,
        due_date: Date.today + 1
      }
      must_respond_with :success

      Movie.find(movie.id).rentals.last.checkout_date.must_equal Date.today
    end

    it "requires a valid movie title" do
      post check_out_path(title: "does not exist"), params: {
        customer_id: customers(:two).id,
        due_date: Date.today + 1
      }
      must_respond_with :not_found
      data = JSON.parse @response.body
      data.must_include "errors"
      data["errors"].must_include "title"
    end

    it "requires a valid customer ID" do
      bad_customer_id = 13371337
      Customer.find_by(id: bad_customer_id).must_be_nil

      post check_out_path(title: movies(:one).title), params: {
        customer_id: bad_customer_id,
        due_date: Date.today + 1
      }
      must_respond_with :not_found
      data = JSON.parse @response.body
      data.must_include "errors"
      data["errors"].must_include "customer_id"
    end

    it "requires a due-date in the future" do
      # Obvious case: actually in the past
      post check_out_path(title: movies(:one).title), params: {
        customer_id: customers(:two).id,
        due_date: Date.today - 1
      }
      must_respond_with :bad_request
      data = JSON.parse @response.body
      data.must_include "errors"
      data["errors"].must_include "due_date"
    end
  end

  describe "check-in" do
    before do
      # Establish a rental
      @rental = Rental.create!(
        movie: movies(:one),
        customer: customers(:two),
        checkout_date: Date.today - 5,
        due_date: Date.today + 5,
        returned: false
      )
    end

    it "marks a rental complete" do
      post check_in_path(title: @rental.movie.title), params: {
        customer_id: @rental.customer.id
      }
      must_respond_with :success

      @rental.reload

      @rental.returned.must_equal true
    end

    it "requires a valid movie title" do
      post check_in_path(title: "does not exist"), params: {
        customer_id: @rental.customer.id
      }
      must_respond_with :not_found
      data = JSON.parse @response.body
      data.must_include "errors"
      data["errors"].must_include "title"
    end

    it "requires a valid customer ID" do
      bad_customer_id = 13371337
      Customer.find_by(id: bad_customer_id).must_be_nil

      post check_in_path(title: @rental.movie.title), params: {
        customer_id: bad_customer_id
      }
      must_respond_with :not_found
      data = JSON.parse @response.body
      data.must_include "errors"
      data["errors"].must_include "customer_id"
    end

    it "requires there to be a rental for that customer-movie pair" do
      post check_in_path(title: movies(:two).title), params: {
        customer_id: customers(:three).id
      }
      must_respond_with :not_found
      data = JSON.parse @response.body
      data.must_include "errors"
      data["errors"].must_include "rental"
    end

    it "requires an un-returned rental" do
      @rental.returned = true
      @rental.save!

      post check_in_path(title: @rental.movie.title), params: {
        customer_id: @rental.customer.id
      }
      must_respond_with :not_found
      data = JSON.parse @response.body
      data.must_include "errors"
      data["errors"].must_include "rental"
    end

    it "if multiple rentals match, ignores returned ones" do
      returned_rental = Rental.create!(
        movie: @rental.movie,
        customer: @rental.customer,
        checkout_date: Date.today - 5,
        due_date: @rental.due_date - 2,
        returned: true
      )

      post check_in_path(title: @rental.movie.title), params: {
        customer_id: @rental.customer.id
      }
      must_respond_with :success

      returned_rental.reload
      @rental.reload

      @rental.returned.must_equal true
    end

    it "returns the rental with the closest due_date" do
      soon_rental = Rental.create!(
        movie: @rental.movie,
        customer: @rental.customer,
        checkout_date: Date.today - 5,
        due_date: @rental.due_date - 2,
        returned: false
      )

      far_rental = Rental.create!(
        movie: @rental.movie,
        customer: @rental.customer,
        checkout_date: Date.today - 5,
        due_date: @rental.due_date + 10,
        returned: false
      )

      post check_in_path(title: @rental.movie.title), params: {
        customer_id: @rental.customer.id
      }
      must_respond_with :success

      soon_rental.reload
      @rental.reload
      far_rental.reload

      soon_rental.returned.must_equal true
      @rental.returned.must_equal false
      far_rental.returned.must_equal false
    end
  end

  describe "overdue" do
    # Note that we *don't* check the actual content,
    # since that is covered by the model tests.
    # Instead we just check the things the controlelr
    # is responsible for.

    it "Returns a JSON array" do
      get overdue_path
      must_respond_with :success
      @response.headers['Content-Type'].must_include 'json'

      # Attempt to parse
      data = JSON.parse @response.body
      data.must_be_kind_of Array
    end

    it "Returns an empty array if no rentals overdue" do
      # Make sure there's none overdue
      Rental.all.each do |r|
        r.returned = true
        r.save!
      end

      get overdue_path
      must_respond_with :success

      data = JSON.parse @response.body
      data.must_be_kind_of Array
      data.length.must_equal 0
    end

    it "Returns expected fields" do
      # Make sure we get something back
      Rental.overdue.length.must_be :>, 0

      get overdue_path
      must_respond_with :success

      data = JSON.parse @response.body
      data.must_be_kind_of Array
      data.length.must_equal Rental.overdue.length

      data.each do |rental|
        rental.must_be_kind_of Hash
        rental.must_include "title"
        rental.must_include "customer_id"
        rental.must_include "name"
        rental.must_include "postal_code"
        rental.must_include "checkout_date"
        rental.must_include "due_date"
      end
    end
  end
end
