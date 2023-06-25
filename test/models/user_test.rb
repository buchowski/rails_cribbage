require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should return is_member == true if user created game" do
    user = User.new()
    user.id = 123
    game = Game.new(123)

    assert(user.is_member(game))
    assert(user.is_creator(game))
  end

  test "should return is_member == true if user joined game" do
    user = User.new()
    user.id = 456
    game = Game.new(123)
    game.player_two_id = user.id

    assert(user.is_member(game))
    assert_not(user.is_creator(game))
  end

  test "should return is_member == false if user does NOT belong to game" do
    user = User.new()
    user.id = 456
    game = Game.new(123)

    assert_not(user.is_member(game))
    assert_not(user.is_creator(game))
  end
end
