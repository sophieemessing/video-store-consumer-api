require 'test_helper'
class CorsHeadersTest < ActionDispatch::IntegrationTest
  test "responses include CORS headers" do
    [host, 'http://localhost:3000', 'null'].each do |host|
      get '/', headers: {origin: host}
      assert_includes response.headers, 'Access-Control-Allow-Origin'
      assert_equal response.headers['Access-Control-Allow-Origin'], '*'
      assert_includes response.headers, 'Access-Control-Allow-Methods'
      %w(GET POST PUT PATCH DELETE OPTIONS).each do |method|
        assert_includes response.headers['Access-Control-Allow-Methods'], method
      end
    end
  end
end
