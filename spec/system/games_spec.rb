require 'rails_helper'

RSpec.describe "Games", type: :system do
  before do
    driven_by(:rack_test)
  end

  first_row = "tbody tr:first-child"
  last_row = "tbody tr:last-child"

  describe "index page" do
    fixtures :games

    it "should display all games in the table" do
      visit games_path

      expect(page).to have_selector "tbody tr", count: 2
      expect(page.find("#{last_row} td:nth-child(2)")).to have_content("bill")
      expect(page.find("#{last_row} td:nth-child(3)").text).to eq("")
      expect(page.find("#{last_row} td:nth-child(4)")).to have_content("waiting_for_player_two")

      expect(page.find("#{first_row} td:nth-child(2)")).to have_content("barbara")
      expect(page.find("#{first_row} td:nth-child(3)")).to have_content("cindy")
      expect(page.find("#{first_row} td:nth-child(4)")).to have_content("discarding")
    end

    it "should navigate to #show page" do
      visit games_path

      open_link = page.find("#{first_row} td:nth-child(7) a")

      expect(open_link).to have_content("open")

      show_page = open_link[:href]

      open_link.click

      expect(page).to have_current_path(show_page)
    end
  end

  describe "show page" do
    fixtures :games
    barbaras_cards = %{5c 4h jh 6h 3h 2h}.split()
    cindys_cards = %{6c 6s 8h 9c as}.split()

    before(:each) do
      page.driver.browser.set_cookie("player_name=barbara")
      visit games_path

      open_link = page.find("#{first_row} td:nth-child(7) a")
      open_link.click
    end

    it "should show the player's cards and hide the opponent's cards" do
      barbaras_cards.each do |card|
        expect(page).to have_selector("##{card}_card")
        expect(page).to have_selector("##{card}_checkbox")
        expect(page).not_to have_selector("##{card}_radio")
      end

      cindys_cards.each do |card|
        expect(page).not_to have_selector("##{card}_card")
        expect(page).not_to have_selector("##{card}_checkbox")
        expect(page).not_to have_selector("##{card}_radio")
      end

      cindys_hidden_cards = page.find_all("#opponent_cards_section .card")
      crib_cards = page.find_all("#crib_cards_section .card")
      cut_card = page.find_all("#cut_cards_section .card")

      expect(cindys_hidden_cards.size).to equal(5)
      expect(crib_cards.size).to equal(1)
      expect(cut_card.size).to equal(0)
    end

    it "should let the players play until there's a winner" do
      # barbara selects two cards and then discards
      page.find("#3h_checkbox").click
      page.find("#2h_checkbox").click
      page.find("#discard_btn").click

      barbaras_cards.without("3h", "2h").each do |card|
        expect(page).to have_selector("##{card}_checkbox")
      end

      # access the game as cindy
      Capybara.reset_sessions!
      page.driver.browser.set_cookie("player_name=cindy")
      visit games_path
      open_link = page.find("#{first_row} td:nth-child(7) a")
      open_link.click

      # cindy has already discarded one card (games.yml) so she discards one additional card
      page.find("#as_checkbox").click
      page.find("#discard_btn").click

      cindys_cards.without("as").each do |card|
        expect(page).not_to have_selector("##{card}_checkbox")
        expect(page).to have_selector("##{card}_radio")
      end
    end
  end
end
