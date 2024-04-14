require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get games_path
    assert_response :success
  end

  test "should allow admin to view admin page" do
    sign_in_as_cindy()
    get admin_path
    assert_response :success
  end

  test "should not allow non-admin to view admin page" do
    sign_in_as_barbara()
    get admin_path
    assert_response 403
  end

  test "should allow anonymous users to view game" do
    get game_path(Game.last.id)
    assert_response :success
  end

  test "should display error_msg when #create is called without player_name" do
    cereal_uri = "/cereal-sweepstakes/how-to-win"

    assert_no_difference("Game.count") do
      post games_path, headers: { "HTTP_REFERER" => cereal_uri }
    end

    assert_redirected_to cereal_uri
    assert_equal flash[:error_msg], "you must log in before you're able to play"
  end

  test "should create new game if player_name is provided" do
    sign_in_as_barbara()

    assert_difference("Game.count", 1) do
      post games_path
    end

    assert_redirected_to games_path
    assert_nil flash[:error_msg]
  end

  test "should allow user to join as player_two" do
    sign_in_as_barbara()

    assert_redirected_to admin_path

    post games_path

    sign_in_as_cindy()

    patch game_path(Game.last.id), params: {type_of_update: "join_game" }

    assert_redirected_to game_path(Game.last.id)
    assert_nil flash[:error_msg]
  end

  test "should not allow user to join if they're already a member" do
    sign_in_as_barbara()
    patch game_path(Game.last.id), params: {type_of_update: "join_game" }

    assert_equal flash[:error_msg], "you already joined this game"
    assert_redirected_to game_path(Game.last.id)
  end

  test "should not allow user to start game before second player has joined" do
    sign_in_as_barbara()

    post games_path

    patch game_path(Game.last.id), params: { type_of_update: "start_game" }

    assert_equal flash[:error_msg], "this game is either not ready to start or has been started already"
  end

  test "should block update if user is not a member of the game" do
    sign_in_as(3)
    patch game_path(Game.last.id), params: { type_of_update: "cut_for_deal" }

    assert_equal flash[:error_msg], "You are not a member of this game"
  end

  test "should allow user to create a bot game" do
    barbara, bot = start_bot_game_as('Barbara')
    cribbage_game = Game.adapt_to_cribbage_game(Game.last)

    assert_equal cribbage_game.players[0].id, barbara.id
    assert_equal cribbage_game.players[1].id, bot.id
    assert_equal cribbage_game.players[1].hand.size, 0
    assert_equal cribbage_game.crib.size, 0
  end

  test "should automatically start game if bot is selected" do
    start_bot_game_as('Barbara')
    cribbage_game = Game.adapt_to_cribbage_game(Game.last)

    assert_equal :cutting_for_deal, cribbage_game.fsm.aasm.current_state
  end

  test "should deal cards immediately after user cuts if is bot game" do
    start_bot_game_as('Barbara')

    patch game_path(Game.last.id), params: { type_of_update: "cut_for_deal" }
    cribbage_game = Game.adapt_to_cribbage_game(Game.last)

    assert_equal :discarding, cribbage_game.fsm.aasm.current_state
    assert_equal 6, cribbage_game.players[0].hand.size
    assert_equal 6, cribbage_game.players[1].hand.size
    assert_equal 0, cribbage_game.crib.size
  end

  test "should discard bot's cards after user has discarded" do
    start_bot_game_as('Barbara')

    patch game_path(Game.last.id), params: { type_of_update: "cut_for_deal" }

    cribbage_game = Game.adapt_to_cribbage_game(Game.last)
    cards_to_discard = cribbage_game.players[0].hand.keys[0..1]

    patch game_path(Game.last.id), params: { type_of_update: "discard", cards: cards_to_discard }

    cribbage_game = Game.adapt_to_cribbage_game(Game.last)
    assert_equal :playing, cribbage_game.fsm.aasm.current_state
    assert_equal 4, cribbage_game.players[0].hand.size
    assert_equal 4, cribbage_game.players[1].hand.size
    assert_equal 4, cribbage_game.crib.size
  end

  test "should play bot's card after user has played" do
    start_bot_game_as('Barbara')

    patch game_path(Game.last.id), params: { type_of_update: "cut_for_deal" }

    cribbage_game = Game.adapt_to_cribbage_game(Game.last)
    cards_to_discard = cribbage_game.players[0].hand.keys[0..1]
    is_barbara_dealer = cribbage_game.dealer.id == cribbage_game.players[0].id

    assert_not_equal cribbage_game.dealer.id, cribbage_game.whose_turn.id, "the non-dealer should play first"

    patch game_path(Game.last.id), params: { type_of_update: "discard", cards: cards_to_discard }

    cribbage_game = Game.adapt_to_cribbage_game(Game.last)
    barbaras_hand = cribbage_game.players[0].hand
    bots_hand = cribbage_game.players[1].hand

    assert_equal :playing, cribbage_game.fsm.aasm.current_state, "top card should have been flipped"

    # TODO this test isn't deterministic. sometimes the bot is the dealer, sometimes not. cut_for_deal is random
    if is_barbara_dealer
      assert_equal 3, get_playable_cards(bots_hand).size, "bot should have played a card"
    else
      assert_equal 4, get_playable_cards(bots_hand).size, "bot should wait for barbara to play"
    end

    assert_equal cribbage_game.players[0].id, cribbage_game.whose_turn.id, "barbara should be next to play"
    assert_equal barbaras_hand.size, 4, "barbara should have discarded"

    patch(
      game_path(Game.last.id),
      params: {
        type_of_update: "play_card",
        card_to_play: get_playable_cards(barbaras_hand).keys.first
      }
    )

    cribbage_game = Game.adapt_to_cribbage_game(Game.last)
    barbaras_hand = cribbage_game.players[0].hand
    bots_hand = cribbage_game.players[1].hand

    assert_equal :playing, cribbage_game.fsm.aasm.current_state
    assert_equal 3, get_playable_cards(barbaras_hand).size, "barbara played a card"

    if is_barbara_dealer
      assert_equal 2, get_playable_cards(bots_hand).size, "bot should have played a 2nd card"
      assert_equal 3, cribbage_game.pile.size
    else
      assert_equal 3, get_playable_cards(bots_hand).size, "bot should have played a 1st card"
      assert_equal 2, cribbage_game.pile.size
    end
  end

  test "should allow anon user to create quick game that is not saved to DB" do
    bot = BotUser.new

    assert_no_difference("Game.count") do
      get "/quick_game", params: { bot_id: bot.id }
    end

    assert_response 200
    assert_nil flash[:error_msg]
  end
end
