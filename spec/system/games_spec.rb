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

    it "should set current player to player_name param" do
      page.driver.browser.set_cookie("player_name=barbara")
      visit games_path

      open_link = page.find("#{first_row} td:nth-child(7) a")
      open_link.click

      barbaras_cards = %{5c 4h jh 6h 3h 2h}.split()

      barbaras_cards.each do |card|
        card_el = page.find("##{card}_checkbox")
        expect(card_el).to_not be_nil
      end

      cindys_cards = page.find("#opponent_cards_section .card")

      expect(cindys_cards.size).to equal(6)
    end
  end
end
