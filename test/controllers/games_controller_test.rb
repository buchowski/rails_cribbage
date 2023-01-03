require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get games_path
    assert_response :success
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
    assert_equal flash[:error_msg], "you must include your player_name in the request"
  end

  test "should create new game if player_name is provided" do
    cereal_uri = "/cereal-sweepstakes/how-to-win"

    assert_difference("Game.count", 1) do
      post games_path, headers: { "HTTP_REFERER" => cereal_uri }, params: { player_name: "judith" }
    end

    assert_redirected_to games_path
    assert_nil flash[:error_msg]
  end

  test "should allow user to join as player_two" do
    post games_path, params: { player_name: "judith" }

    assert_equal cookies[:player_name], "judith"

    patch game_path(Game.last.id), params: { player_name: "bobby", type_of_update: "join_game" }

    assert_response :redirect
    assert_equal cookies[:player_name], "bobby"
    assert_nil flash[:error_msg]
  end

  test "should not allow user to join if they're already a member" do
    post games_path, params: { player_name: "judith" }
    patch game_path(Game.last.id), params: { player_name: "judith", type_of_update: "join_game" }

    assert_equal flash[:error_msg], "uncaught throw \"you already joined this game\""
    assert_equal cookies[:player_name], "judith"
  end

  test "should not allow user to start game before second player has joined" do
    post games_path, params: { player_name: "michael" }
    patch game_path(Game.last.id), params: { type_of_update: "start_game" }

    assert_equal flash[:error_msg], "uncaught throw \"this game is either not ready to start or has been started already\""
  end

  test "should block update if user is not a member of the game" do
    post games_path, params: { player_name: "judith" }
    patch game_path(Game.last.id), params: { player_name: "bobby", type_of_update: "join_game" }
    patch game_path(Game.last.id), params: { type_of_update: "start_game" }
    patch game_path(Game.last.id), params: { player_name: "turnstile", type_of_update: "cut_for_deal" }

    assert_equal flash[:error_msg], "uncaught throw \"You are not a member of this game\""
    assert_equal cookies[:player_name], "turnstile"
  end
end
