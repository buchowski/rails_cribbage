class GamesController < ApplicationController
  def index
    @games = Game.all
  end
  def create
    creator_id = params["creator_id"]

    game = Game.new creator_id: creator_id

    p "johnny", game

  end

end
