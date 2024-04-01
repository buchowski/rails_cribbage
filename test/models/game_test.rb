require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "should not initialize without a creator_id" do
    game = Game.new()
    assert_not(game.save())
  end

  test "should convert a CribbageGame::Game instance to hash" do
    game = CribbageGame::Game.new()

    game.players[0].id = 123
    game.players[1].id = 456

    game_hash = Game.adapt_to_active_record(game)

    assert_equal(game_hash[:player_one_id], 123)
    assert_equal(game_hash[:player_two_id], 456)
    assert_equal(game_hash[:current_fsm_state], :cutting_for_deal)
  end

  test "should convert an ActiveRecord Game model to a CribbageGame::Game instance" do
    spookeys_id = 4
    cribbage_game = CribbageGame::Game.new()
    cribbage_game.players[0].id = spookeys_id
    adapted_game = Game.adapt_to_active_record(cribbage_game)
    adapted_game[:player_two_id] = nil
    adapted_game[:current_fsm_state] = :waiting_for_player_two
    game_model = Game.new(adapted_game)
    game = Game.adapt_to_cribbage_game(game_model)

    assert_equal(game.players[0].id, spookeys_id)
    assert_equal(game.players[0].name, "Spookey-Bot")
    assert_nil(game.players[1].id)
    assert_equal(game.players[1].name, "")
    assert_equal(game.fsm.aasm.current_state, :waiting_for_player_two)
  end
end
