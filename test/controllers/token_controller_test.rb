require "test_helper"

class TokenControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get token_index_url
    assert_response :success
  end
end
