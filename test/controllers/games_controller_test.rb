require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get games_path
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

    assert_difference("Game.count") do
      post games_path, headers: { "HTTP_REFERER" => cereal_uri }, params: { player_name: "judith" }
    end

    assert_redirected_to games_path
    assert_nil flash[:error_msg]
  end
end
