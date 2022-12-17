class GamesController < ApplicationController
  def index
    @games = GameService.all
  end
  def show
    @game = get_game()
  end
  def create
    creator_id = params[:creator_id]
    @game = GameService.new(creator_id)

    if @game.save
      redirect_to games_path
    else
      p "error: game failed to save", @game
    end
  end
  def update
    game = get_game()
    type_of_update = params[:type_of_update]

    begin
      case type_of_update
      when "join_game" then join_game(game)
      when "start_game" then start_game(game)
      when "cut_for_deal" then cut_for_deal(game)
      end
    rescue => exception
      flash[:error_msg] = exception
    ensure
      redirect_to game_path
    end
  end

  def destroy
    game = get_game()

    if game.destroy
      redirect_to games_path
    else
      p "error: game failed to delete", @game
    end
  end

  private

  def get_game
    game_id = params[:id]
    GameService.find(game_id)
  end

  def join_game(game)
    if game.player_two_id.nil?
      was_created_by_sally = game.player_one_id == 'sally'
      game.player_two_id = was_created_by_sally ? 'hank' : 'sally'
      game.current_fsm_state = :waiting_to_start

      if !game.save then throw "failed to join game" end
    else
      throw "you're not allowed to join. too many players already"
    end
  end

  def start_game(game)
    game.current_fsm_state = GameService.getFsmStartState()

    if game.current_fsm_state != :waiting_to_start
      throw "this game is either not ready to start or has been started already"
    end

    if !game.save then throw "unable to start game" end
  end

  def cut_for_deal(game)
    p "bobby", game
  end
end
