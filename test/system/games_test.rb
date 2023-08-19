require "application_system_test_case"

class GamesTest < ApplicationSystemTestCase
  test "single player happy path" do
    visit games_url
    click_on "Login"

    fill_in "Your email", with: "martin@express-tops.net"
    fill_in "Password", with: "secret"
    click_on "Sign in"

    click_on "New Game"

    assert_text "Spookey-Bot"
    click_on "open"

    click_on "Cut for deal"
    assert_text "Select two cards to discard"

    who_is_the_dealer = find_by_id "who-is-the-dealer"
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

    if are_you_the_dealer
      assert_text("Waiting for Spookey-bot to play a card")
    else
      assert_text("Select a card to play")
    end

    cards = find_all "input[type='checkbox']"
    assert_equal 0, cards.size, "should have discarded last card and no longer see checkboxes"
  end
end
