class GamesController < ApplicationController
  def index
    @games = Game.all
  end
  def show
    game_model = get_game_model()
    cribbage_game = get_cribbage_game(game_model)
    @cards = cribbage_game.players[0].hand
    @game = game_model
  end
  def create
    creator_id = params[:creator_id]
    @game = Game.new(creator_id)

    if !@game.save
      flash[:error_msg] = "error: failed to save game"
    end
    redirect_to games_path
  end
  def update
    game_model = get_game_model()
    type_of_update = params[:type_of_update]

    begin
      if type_of_update == "join_game"
        join_game(game_model)
      elsif type_of_update == "start_game"
        start_game(game_model)
      else
        game = get_cribbage_game(game_model)

        case type_of_update
        when "cut_for_deal"
          game.cut_for_deal()
        when "deal"
          game.deal()
        when "discard"
          discard(game)
        end

        game_model.update(Game.adapt_to_active_record(game))
      end
    rescue => exception
      # truncate exception.message to prevent cookieoverflow
      flash[:error_msg] = exception.message[0, 100]
    ensure
      redirect_to game_path
    end
  end

  def destroy
    game = get_game_model()

    if !game.destroy
      flash[:error_msg] = "error: failed to delete game"
    end
    redirect_to games_path
  end

  private

  def get_game_model
    game_id = params[:id]
    Game.find(game_id)
  end

  def join_game(game_model)
    if game_model.player_two_id.nil?
      was_created_by_sally = game_model.player_one_id == 'sally'
      game_model.player_two_id = was_created_by_sally ? 'hank' : 'sally'
      game_model.current_fsm_state = :waiting_to_start

      if !game_model.save then throw "failed to join game" end
    else
      throw "you're not allowed to join. too many players already"
    end
  end

  def start_game(game_model)
    if game_model.current_fsm_state.to_sym != :waiting_to_start
      throw "this game is either not ready to start or has been started already"
    end

    game_model.current_fsm_state = :cutting_for_deal

    if !game_model.save then throw "unable to start game" end
  end

  def get_cribbage_game(game_model)
    Game.adapt_to_cribbage_game(game_model)
  end

  def discard(game)
    p "discarding", game
  end
end
