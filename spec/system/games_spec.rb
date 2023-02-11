require 'rails_helper'

t = Proc.new do |key, data| Translations.en(key, data) end

def access_page_as(player_name)
  Capybara.reset_sessions!
  page.driver.browser.set_cookie("player_name=#{player_name}")

  visit games_path
  page.click_on("open", :match => :first)
end

def play_card_as(player_name, card_id)
  access_page_as(player_name)
  expect(page.find("#game_play_message").text).to eq("Select a card to play")

  page.find("##{card_id}_radio").click
  page.find("#play_btn").click
  expect(page.find("#game_play_message").text).to eq("Waiting for opponent to play a card")
end

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
  end

  describe "show page" do
    fixtures :games
    barbaras_cards = %{5c 4h jh 6h 3h 2h}.split()
    cindys_cards = %{6c 6s 8h 9c as}.split()

    before(:each) do
      access_page_as("barbara")
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

      expect(cindys_hidden_cards.size).to eq(5)
      expect(crib_cards.size).to eq(1)
      expect(cut_card.size).to eq(0)
    end

    it "should let the players play until there's a winner" do
      # barbara selects two cards and then discards
      page.find("#3h_checkbox").click
      page.find("#2h_checkbox").click
      page.find("#discard_btn").click

      barbaras_cards.without("3h", "2h").each do |card|
        expect(page).to have_selector("##{card}_checkbox")
      end

      access_page_as("cindy")

      # cindy has already discarded one card (games.yml) so she discards one additional card
      page.find("#as_checkbox").click
      page.find("#discard_btn").click

      cindys_cards.without("as").each do |card|
        expect(page).not_to have_selector("##{card}_checkbox")
        expect(page).to have_selector("##{card}_radio")
      end

      expect(page.find("#game_play_message").text).to eq("Waiting for opponent to play a card")

      play_card_as("barbara", "6h")
      play_card_as("cindy", "9c")

      expect(page.find("#game_play_alert").text).to eq("You scored 2 points!")
      expect(page.find("#your_score").text).to eq("Your score: 2")
      expect(page.find("#opponents_score").text).to eq("Opponent's score: 0")

      play_card_as("barbara", "jh")
      play_card_as("cindy", "6s")

      expect(page.find("#game_play_alert").text).to eq("You scored 2 points!")
      expect(page.find("#your_score").text).to eq("Your score: 4")
      expect(page.find("#opponents_score").text).to eq("Opponent's score: 0")
    end
  end
end
