class GamesController < ApplicationController
  def index
    @games = Game.all
  end
  def create
    creator_id = params[:creator_id]
    @game = Game.new(creator_id)

    if @game.save
      p "success: game was saved", @game

      redirect_to games_path
    else
      p "error: game failed to save", @game
    end
  end

  def destroy
    game_id = params[:id]
    game = Game.find(game_id)

    if game.destroy
      p "success: game was deleted", @game

      redirect_to games_path
    else
      p "error: game failed to delete", @game
    end
  end
end
