require "application_system_test_case"

class SectionsTest < ApplicationSystemTestCase
  setup do
    @section = sections(:one)
  end

  test "visiting the index" do
    visit sections_url
    assert_selector "h1", text: "Sections"
  end

  test "creating a Section" do
    visit sections_url
    click_on "New Section"

    fill_in "All Paid", with: @section.all_paid
    fill_in "Games Count", with: @section.games_count
    fill_in "Group", with: @section.group_id
    fill_in "Rate", with: @section.rate
    fill_in "Section Players Count", with: @section.section_players_count
    fill_in "Status", with: @section.status
    click_on "Create Section"

    assert_text "Section was successfully created"
    click_on "Back"
  end

  test "updating a Section" do
    visit sections_url
    click_on "Edit", match: :first

    fill_in "All Paid", with: @section.all_paid
    fill_in "Games Count", with: @section.games_count
    fill_in "Group", with: @section.group_id
    fill_in "Rate", with: @section.rate
    fill_in "Section Players Count", with: @section.section_players_count
    fill_in "Status", with: @section.status
    click_on "Update Section"

    assert_text "Section was successfully updated"
    click_on "Back"
  end

  test "destroying a Section" do
    visit sections_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Section was successfully destroyed"
  end
end
