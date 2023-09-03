require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should return is_member == true if user created game" do
    user = User.new()
    user.id = 123
    cribbage_game = CribbageGame::Game.new()
    adapted_game = Game.adapt_to_active_record(cribbage_game)
    adapted_game[:player_one_id] = user.id
    game = Game.new(adapted_game)

    assert(user.is_member(game))
    assert(user.is_creator(game))
  end

  test "should return is_member == true if user joined game" do
    user = User.new()
    user.id = 456
    cribbage_game = CribbageGame::Game.new()
    adapted_game = Game.adapt_to_active_record(cribbage_game)
    adapted_game[:player_two_id] = user.id
    game = Game.new(adapted_game)

    assert(user.is_member(game))
    assert_not(user.is_creator(game))
  end

  test "should return is_member == false if user does NOT belong to game" do
    user = User.new()
    user.id = 456
    cribbage_game = CribbageGame::Game.new()
    adapted_game = Game.adapt_to_active_record(cribbage_game)
    game = Game.new(adapted_game)

    assert_not(user.is_member(game))
    assert_not(user.is_creator(game))
  end
end
