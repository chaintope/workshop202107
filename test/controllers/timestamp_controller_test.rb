require "test_helper"

class TimestampControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get timestamp_index_url
    assert_response :success
  end
end
