require 'test_helper'

class SectionPlayersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @section_player = section_players(:one)
  end

  test "should get index" do
    get section_players_url
    assert_response :success
  end

  test "should get new" do
    get new_section_player_url
    assert_response :success
  end

  test "should create section_player" do
    assert_difference('SectionPlayer.count') do
      post section_players_url, params: { section_player: { paid: @section_player.paid, player_id: @section_player.player_id, section_id: @section_player.section_id, total: @section_player.total } }
    end

    assert_redirected_to section_player_url(SectionPlayer.last)
  end

  test "should show section_player" do
    get section_player_url(@section_player)
    assert_response :success
  end

  test "should get edit" do
    get edit_section_player_url(@section_player)
    assert_response :success
  end

  test "should update section_player" do
    patch section_player_url(@section_player), params: { section_player: { paid: @section_player.paid, player_id: @section_player.player_id, section_id: @section_player.section_id, total: @section_player.total } }
    assert_redirected_to section_player_url(@section_player)
  end

  test "should destroy section_player" do
    assert_difference('SectionPlayer.count', -1) do
      delete section_player_url(@section_player)
    end

    assert_redirected_to section_players_url
  end
end
