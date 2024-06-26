require 'rails_helper'

def access_page_as(player_name, route = nil)
  click_button "Log out" if page.has_button? "Log out"
  user = User.find_by(name: player_name.upcase_first)

  visit new_user_session_path
  fill_in "Email", with: user.email
  fill_in "Password", with: "secret"
  click_button "Log in"
  visit route if !route.nil?
end

def play_card_as(player_name, card_id)
  t = Proc.new do |key, data| Translations.en(key, data) end
  access_page_as(player_name, game_path(2))
  expect(page.find("#game_play_message").text).to eq("Select a card to play")
  expect(page.find("#game_play_message").text).to eq(t.call("playing.you"))
  expect(page).not_to have_selector("#refresh_btn")

  page.find("##{card_id}_radio").click
  page.find("#play_btn").click
  expect(page.has_css?("#error_msg")).to be false
end

def should_be_opponents_turn(opponent_name)
  t = Proc.new do |key, data| Translations.en(key, data) end
  expect(page.find("#game_play_message").text).to eq("Waiting for #{opponent_name} to play a card")
  expect(page.find("#game_play_message").text).to eq(t.call("playing.opponent", {opponent_name: opponent_name}))
end

def expect_scores_to_be(your_score, opponent_score, opponent_name, expected_play_by_play)
  expect(page.find("#your_score").text).to eq("You have #{your_score} points")
  expect(page.find("#opponent_score").text).to eq("#{opponent_name} has #{opponent_score} points")

  play_by_play = page.all("#play_by_play_section li").map(&:text)
  p "expected #{expected_play_by_play} got #{play_by_play}"
  expect(play_by_play.size).to eq(expected_play_by_play.size)

  if expected_play_by_play.empty?
    expect(play_by_play.size).to eq(0)
  else
    expected_play_by_play.each_with_index do |msg, i|
      expect(play_by_play[i]).to eq(msg)
    end
  end
end

def expect_pile_score_to_be(pile_score)
  expect(page.find("#pile_score").text).to eq("Pile score: #{pile_score}")
end

RSpec.describe "Games", type: :system do
  before do
    driven_by(:rack_test)
  end

  first_row = ".game_row:first-child"
  last_row = ".game_row:last-child"

  describe "admin page" do
    fixtures :games, :users

    it "should display all games in the table" do
      access_page_as "cindy", admin_path

      expect(page).to have_selector ".game_row", count: 3
      expect(page.find("#{last_row} .creator_name")).to have_content("Barbara")
      expect(page.find("#{last_row} .opponent_name").text).to have_content("Cindy")
      expect(page.find("#{last_row} .game_state")).to have_content("playing")

      expect(page.find("#{first_row} .creator_name")).to have_content("Barbara")
      expect(page.find("#{first_row} .opponent_name")).to have_content("")
      expect(page.find("#{first_row} .game_state")).to have_content("waiting_for_player_two")
    end
  end

  describe "show page" do
    fixtures :games, :users
    barbaras_cards = %{5c 4h jh 6h 3h 2h}.split()
    cindys_cards = %{6c 6s 8h 9c as}.split()

    it "should show the player's cards and hide the opponent's cards" do
      access_page_as("barbara", game_path(2))

      barbaras_cards.each do |card|
        expect(page).to have_selector(".card_#{card}")
        expect(page).to have_selector("##{card}_checkbox")
        expect(page).not_to have_selector("##{card}_radio")
      end

      cindys_cards.each do |card|
        expect(page).not_to have_selector(".card_#{card}")
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
      access_page_as("barbara", game_path(2))
      # barbara selects two cards and then discards
      expect(page.find("#game_play_message").text).to eq("Select two cards to discard")
      page.find("#3h_checkbox").click
      page.find("#2h_checkbox").click
      page.find("#discard_btn").click
      expect(page.find("#game_play_message").text).to eq("Waiting for Cindy to discard")

      barbaras_cards.without("3h", "2h").each do |card|
        expect(page).to have_selector("##{card}_checkbox")
      end

      access_page_as("cindy", game_path(2))
      expect(page.find("#game_play_message").text).to eq("Select one card to discard")

      # cindy has already discarded one card (games.yml) so she discards one additional card
      page.find("#as_checkbox").click
      page.find("#discard_btn").click

      cindys_cards.without("as").each do |card|
        expect(page).not_to have_selector("##{card}_checkbox")
        expect(page).to have_selector("##{card}_radio")
      end

      expect(page.find("#game_play_message").text).to eq("Waiting for Barbara to play a card")
      # TODO write test to only show the refresh button if it's a bot game
      expect(page).not_to have_selector("#refresh_btn")

      play_card_as("barbara", "6h")
      should_be_opponents_turn("Cindy")
      expect_pile_score_to_be(6)

      play_card_as("cindy", "9c")
      should_be_opponents_turn("Barbara")
      expect_pile_score_to_be(15)
      expect_scores_to_be(2, 0, "Barbara", ["You played a 9c", "You scored 2 points"])

      play_card_as("barbara", "jh")
      should_be_opponents_turn("Cindy")
      expect_pile_score_to_be(25)

      play_card_as("cindy", "6s") #31
      should_be_opponents_turn("Barbara")
      expect_pile_score_to_be(0)
      expect_scores_to_be(4, 0, "Barbara", ["You played a 6s", "You scored 2 points"])

      play_card_as("barbara", "5c")
      should_be_opponents_turn("Cindy")
      expect_pile_score_to_be(5)

      play_card_as("cindy", "6c")
      should_be_opponents_turn("Barbara")
      expect_pile_score_to_be(11)

      play_card_as("barbara", "4h") #15 & 3-card run (4h, 5c, 6c) gives us 5 points
      expect_scores_to_be(5, 4, "Cindy", ["You played a 4h", "You scored 5 points"])
      expect(page.find("#game_play_message").text).to eq("Game over")

      access_page_as("cindy", game_path(2))
      expect(page.find("#game_play_message").text).to eq("Game over")
    end
  end
end
