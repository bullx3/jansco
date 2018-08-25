require 'test_helper'

class PersonalControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get personal_index_url
    assert_response :success
  end

  test "should get profit" do
    get personal_profit_url
    assert_response :success
  end

end
