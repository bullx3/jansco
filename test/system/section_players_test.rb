require "application_system_test_case"

class SectionPlayersTest < ApplicationSystemTestCase
  setup do
    @section_player = section_players(:one)
  end

  test "visiting the index" do
    visit section_players_url
    assert_selector "h1", text: "Section Players"
  end

  test "creating a Section player" do
    visit section_players_url
    click_on "New Section Player"

    fill_in "Paid", with: @section_player.paid
    fill_in "Player", with: @section_player.player_id
    fill_in "Section", with: @section_player.section_id
    fill_in "Total", with: @section_player.total
    click_on "Create Section player"

    assert_text "Section player was successfully created"
    click_on "Back"
  end

  test "updating a Section player" do
    visit section_players_url
    click_on "Edit", match: :first

    fill_in "Paid", with: @section_player.paid
    fill_in "Player", with: @section_player.player_id
    fill_in "Section", with: @section_player.section_id
    fill_in "Total", with: @section_player.total
    click_on "Update Section player"

    assert_text "Section player was successfully updated"
    click_on "Back"
  end

  test "destroying a Section player" do
    visit section_players_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Section player was successfully destroyed"
  end
end
