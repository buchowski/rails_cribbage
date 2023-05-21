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

    assert_equal(game_hash["player_one_id"], 123)
    assert_equal(game_hash["player_two_id"], 456)
    assert_equal(game_hash["current_fsm_state"], :cutting_for_deal)
  end

  test "should convert an ActiveRecord Game model to a CribbageGame::Game instance" do
    barbaras_id = 1
    game_model = Game.new(barbaras_id)
    user_one = User.find_by_id(barbaras_id)

    game = Game.adapt_to_cribbage_game(game_model, user_one, nil)

    assert_equal(game.players[0].id, barbaras_id)
    assert_equal(game.players[0].name, "Barbara")
    assert_nil(game.players[1].id)
    assert_equal(game.fsm.aasm.current_state, :waiting_for_player_two)
  end
end
