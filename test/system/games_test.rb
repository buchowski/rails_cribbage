require "application_system_test_case"

class GamesTest < ApplicationSystemTestCase
  test "single player happy path" do
    visit games_url
    within "#header_actions" do
      click_on "Login"
    end

    fill_in "Email", with: "martin@express-tops.net"
    fill_in "Password", with: "secret"
    click_on "Log in"

    click_on "New Single-Player Game"

    assert_text "Spookey-Bot"
    click_on "open"

    click_on "Cut for deal"

    # in a bot game we let the user deal even if they're not the dealer
    assert_button "Deal cards"
    # but the cards will be automatically dealt after a wait
    assert_text "Select two cards to discard", wait: 0.2

    who_is_the_dealer = find_by_id "who_is_the_dealer"
    are_you_the_dealer = who_is_the_dealer.text == "You are the dealer"

    cards = find_all "input[type='checkbox']"
    assert_equal 6, cards.size, "should have been dealt 6 cards"

    # discard first card
    check cards.first[:id]
    click_on "Discard"
    assert_text "Select one card to discard"
    cards = find_all "input[type='checkbox']"
    assert_equal 5, cards.size, "should have discarded one card"

    # discard second card
    check cards.last[:id]
    click_on "Discard"

    assert_text "Waiting for Spookey-bot to discard"

    if are_you_the_dealer
      # on the BE the bot plays a card immediately after discarding but it's rendered after the animation delay
      assert_text "Spookey-Bot played", wait: 0.2
    else
      assert_text "Select a card to play", wait: 0.2
    end

    cards = find_all "input[type='checkbox']"
    assert_equal 0, cards.size, "should have discarded last card and no longer see checkboxes"
  end
end
