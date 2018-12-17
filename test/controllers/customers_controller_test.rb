require 'test_helper'

class MoviesControllerTest < ActionDispatch::IntegrationTest

  describe "List customers" do
    it "returns a JSON array" do
      get customers_path
      must_respond_with :success
      @response.headers['Content-Type'].must_include 'json'

      # Attempt to parse
      data = JSON.parse @response.body
      data.must_be_kind_of Array
    end

    it "should return many customer fields" do
      get customers_path
      must_respond_with :success

      data = JSON.parse @response.body
      data.each do |customer|
        customer.must_include "id"
        customer.must_include "name"
        customer.must_include "registered_at"
        customer.must_include "postal_code"
        customer.must_include "phone"
        customer.must_include "account_credit"
        customer.must_include "movies_checked_out_count"
      end
    end



    it "returns all customers when no query params are given" do
      get customers_path
      assert_response :success

      data = JSON.parse @response.body
      data.length.must_equal Customer.count

      expected_names = {}
      Customer.all.each do |customer|
        expected_names[customer["name"]] = false
      end

      data.each do |customer|
        expected_names[customer["name"]].must_equal false
        expected_names[customer["name"]] = true
      end
    end

    describe "sorting" do
      it "can sort by name" do
        get customers_path, params: { sort: 'name' }
        assert_response :success

        data = JSON.parse @response.body
        data.length.must_equal Customer.count

        # Verify sorted order
        data.each_with_index do |customer, i|
          if i + 1 >= data.length
            break
          end

          customer['name'].must_be :<=, data[i+1]['name']
        end
      end

      it "can sort by registered_at" do
        get customers_path, params: { sort: 'registered_at' }
        assert_response :success

        data = JSON.parse @response.body
        data.length.must_equal Customer.count

        # Verify sorted order
        data.each_with_index do |customer, i|
          if i + 1 >= data.length
            break
          end

          DateTime.parse(customer['registered_at']).must_be :<=, DateTime.parse(data[i+1]['registered_at'])
        end
      end

      it "can sort by postal_code" do
        get customers_path, params: { sort: 'postal_code' }
        assert_response :success

        data = JSON.parse @response.body
        data.length.must_equal Customer.count

        # Verify sorted order
        data.each_with_index do |customer, i|
          if i + 1 >= data.length
            break
          end

          customer['postal_code'].must_be :<=, data[i+1]['postal_code']
        end
      end

      it "returns an error for an invalid sort field" do
        get customers_path, params: { sort: 'gnome' }
        assert_response :bad_request

        data = JSON.parse @response.body
        data.must_be_kind_of Hash

        data.must_include 'errors'
        data['errors'].must_include 'sort'
      end
    end

    describe "pagination" do
      it "can restrict entries per page" do
        Customer.count.must_be :>, 2
        get customers_path, params: { n: 2 }
        assert_response :success

        data = JSON.parse @response.body
        data.length.must_equal 2
      end

      it "can return different pages" do
        Customer.count.must_be :>, 2
        get customers_path, params: { n: 2, p: 1 }
        assert_response :success

        page_one_data = JSON.parse @response.body
        page_one_data.length.must_equal 2
        page_one_ids = page_one_data.map { |c| c['id'] }

        get customers_path, params: { n: 2, p: 2 }
        assert_response :success

        page_two_data = JSON.parse @response.body

        page_two_data.each do |customer|
          page_one_ids.wont_include customer['id']
        end
      end

      it "Handles pagination and sorting" do
        Customer.count.must_be :>, 2

        # Get first page
        get customers_path, params: { sort: 'name', n: 2, p: 1 }
        assert_response :success

        data = JSON.parse @response.body
        data.length.must_equal 2
        all_names = data.map { |c| c['name'] }

        # Get second page
        get customers_path, params: { sort: 'name', n: 2, p: 2 }
        assert_response :success

        data = JSON.parse @response.body
        all_names += data.map { |c| c['name'] }

        # Verify all data is sorted
        all_names.each_with_index do |name, i|
          break if i + 1 >= all_names.length
          name.must_be :<=, all_names[i+1]
        end
      end

      # it "errors on negative numbers" do
      #   get customers_url, params: { n: -2, p: 1 }
      #   assert_response :bad_request
      #
      #   get customers_url, params: { n: 2, p: -1 }
      #   assert_response :bad_request
      # end

      it "returns an empty array past the end" do
        Customer.count.must_be :<, 10000

        # Get first page
        get customers_path, params: { n: 10, p: 1001 }
        must_respond_with :success

        data = JSON.parse @response.body
        data.length.must_equal 0
      end

      it "handles fewer entries left than page size" do
        Customer.count.must_be :<, 10000

        # Get first page
        get customers_path, params: { n: 10000, p: 1 }
        assert_response :success

        data = JSON.parse @response.body
        data.length.must_equal Customer.count
      end
    end
  end
end