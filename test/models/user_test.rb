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

  test "should return valid? = false if name not present" do
    user = User.new()
    assert_not(user.valid?)
  end

  test "should return valid? = false if name has invalid length" do
    user = User.new(:name => "a")
    user_two = User.new(:name => 30.times.map { "a" }.join)
    assert_not(user.valid?)
    assert_not(user_two.valid?)
  end

  test "should return valid? = true if name has valid length" do
    user = User.new(:name => "bman")
    assert(user.valid?)
  end

end
