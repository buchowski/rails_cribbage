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

    it "should show the player's cards and hide the opponent's cards" do
      page.driver.browser.set_cookie("player_name=barbara")
      visit games_path

      open_link = page.find("#{first_row} td:nth-child(7) a")
      open_link.click

      barbaras_cards = %{5c 4h jh 6h 3h 2h}.split()
      cindys_cards = %{6c 6s 8h 9c as}.split()

      # we're logged in as barbara so we can see all her cards
      barbaras_cards.each do |card|
        expect(page).to have_selector("##{card}_checkbox")
        expect(page).not_to have_selector("##{card}_radio")
      end

      # cindy is the opponent so her cards are hidden (but we know how many cards she has)
      cindys_cards.each do |card|
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
  end
end
