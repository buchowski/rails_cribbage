class GamesController < ApplicationController
  def index
    @games = Game.all
  end
  def create
    creator_id = params[:creator_id]
    @game = Game.new(creator_id)

    if @game.save
      redirect_to games_path
    else
      p "error: game failed to save", @game
    end
  end
  def update
    game_id = params[:id]
    type_of_update = params[:type_of_update]

    begin
      case type_of_update
      when "join_game" then join_game(game_id)
      end
    rescue => exception
      flash[:error_msg] = exception
    ensure
      redirect_to games_path
    end
  end

  def destroy
    game_id = params[:id]
    game = Game.find(game_id)

    if game.destroy
      redirect_to games_path
    else
      p "error: game failed to delete", @game
    end
  end

  private

  def join_game(game_id)
    game = Game.find(game_id)

    if game.player_two_id.nil?
      was_created_by_sally = game.player_one_id == 'sally'
      game.player_two_id = was_created_by_sally ? 'hank' : 'sally'

      if !game.save then throw "failed to join game" end
    else
      throw "you're not allowed to join. too many players already"
    end
  end
end
