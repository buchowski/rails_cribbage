require 'rails_helper'


def access_page_as(player_name)
  Capybara.reset_sessions!
  page.driver.browser.set_cookie("player_name=#{player_name}")

  visit games_path
  page.click_on("open", :match => :first)
end

def play_card_as(player_name, card_id)
  t = Proc.new do |key, data| Translations.en(key, data) end
  access_page_as(player_name)
  expect(page.find("#game_play_message").text).to eq("Select a card to play")
  expect(page.find("#game_play_message").text).to eq(t.call("playing.you"))

  page.find("##{card_id}_radio").click
  page.find("#play_btn").click
  expect(page.has_css?("#error_msg")).to be false
end

def should_be_opponents_turn(opponent_name)
  t = Proc.new do |key, data| Translations.en(key, data) end
  expect(page.find("#game_play_message").text).to eq("Waiting for #{opponent_name} to play a card")
  expect(page.find("#game_play_message").text).to eq(t.call("playing.opponent", {opponent_name: opponent_name}))
end

def expect_scores_to_be(your_score, opponent_score, opponent_name, score_msg)
  expect(page.find("#your_score").text).to eq("You have #{your_score} points")
  expect(page.find("#opponent_score").text).to eq("#{opponent_name} has #{opponent_score} points")
  expect(page.find("#game_play_alert").text).to eq(score_msg)
end

def expect_pile_score_to_be(pile_score)
  expect(page.find("#pile_score").text).to eq("Pile score: #{pile_score}")
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

      cindys_hidden_cards = page.find_all("#opponent_cards_section [data-role='card']")
      crib_cards = page.find_all("#crib_cards_section [data-role='card']")
      cut_card = page.find_all("#cut_cards_section [data-role='card']")

      expect(cindys_hidden_cards.size).to eq(5)
      expect(crib_cards.size).to eq(1)
      expect(cut_card.size).to eq(0)
    end

    it "should let the players play until there's a winner" do
      # barbara selects two cards and then discards
      expect(page.find("#game_play_message").text).to eq("Select two cards to discard")
      page.find("#3h_checkbox").click
      page.find("#2h_checkbox").click
      page.find("#discard_btn").click
      expect(page.find("#game_play_message").text).to eq("Waiting for Cindy to discard")

      barbaras_cards.without("3h", "2h").each do |card|
        expect(page).to have_selector("##{card}_checkbox")
      end

      access_page_as("cindy")
      expect(page.find("#game_play_message").text).to eq("Select one card to discard")

      # cindy has already discarded one card (games.yml) so she discards one additional card
      page.find("#as_checkbox").click
      page.find("#discard_btn").click

      cindys_cards.without("as").each do |card|
        expect(page).not_to have_selector("##{card}_checkbox")
        expect(page).to have_selector("##{card}_radio")
      end

      expect(page.find("#game_play_message").text).to eq("Waiting for Barbara to play a card")

      play_card_as("barbara", "6h")
      should_be_opponents_turn("Cindy")
      expect_pile_score_to_be(6)

      play_card_as("cindy", "9c")
      should_be_opponents_turn("Barbara")
      expect_pile_score_to_be(15)
      expect_scores_to_be(2, 0, "Barbara", "You scored 2 points!")

      play_card_as("barbara", "jh")
      should_be_opponents_turn("Cindy")
      expect_pile_score_to_be(25)

      play_card_as("cindy", "6s") #31
      should_be_opponents_turn("Barbara")
      expect_pile_score_to_be(0)
      expect_scores_to_be(4, 0, "Barbara", "You scored 2 points!")

      play_card_as("barbara", "5c")
      should_be_opponents_turn("Cindy")
      expect_pile_score_to_be(5)

      play_card_as("cindy", "6c")
      should_be_opponents_turn("Barbara")
      expect_pile_score_to_be(11)

      play_card_as("barbara", "4h") #15 & 3-card run (4h, 5c, 6c) gives us 5 points
      expect_scores_to_be(5, 4, "Cindy", "You scored 5 points! You won the game!")
      expect(page.find("#game_play_message").text).to eq("Game over")

      access_page_as("cindy")
      expect(page.find("#game_play_message").text).to eq("Game over")
      expect(page.find("#game_play_alert").text).to eq("Barbara won the game.")
    end
  end
end
