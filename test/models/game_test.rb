require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "should not initialize without a creator_id" do
    game = Game.new()
    assert_not(game.save())
  end

  test "should convert a CribbageGame::Game instance to hash" do
    game = CribbageGame::Game.new()

    game.players[0].id = "player_uno"
    game.players[1].id = "player_dos"

    game_hash = Game.adapt_to_active_record(game)

    assert_equal(game_hash["player_one_id"], "player_uno")
    assert_equal(game_hash["player_two_id"], "player_dos")
    assert_equal(game_hash["current_fsm_state"], :cutting_for_deal)
  end

  test "should convert an ActiveRecord Game model to a CribbageGame::Game instance" do
    game_model = Game.new("tony_tiger")

    game = Game.adapt_to_cribbage_game(game_model)

    assert_equal(game.players[0].id, "tony_tiger")
    assert_nil(game.players[1].id)
    assert_equal(game.fsm.aasm.current_state, :waiting_for_player_two)
  end
end
