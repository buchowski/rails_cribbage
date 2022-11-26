class Game < ApplicationRecord
  serialize :player_one_cards, Array
  serialize :player_two_cards, Array
  serialize :pile_cards, Array
  serialize :crib_cards, Array

  def initialize params
    p "duffy", params
    cribbage_game = CribbageGame::Game.new

    super(adaptCribbageGame(cribbage_game));
  end

  private

  def safelyGetPlayerId player
    if !player
      return nil
    end
    player.id
  end

  def adaptCribbageGame game
    player_one = game.players[0]
    player_two = game.players[1]

    {
      "player_one_id" => player_one.id,
      "player_two_id" => player_two.id,
      "player_one_cards" => player_one.hand,
      "player_two_cards" => player_two.hand,
      "player_one_points" => player_one.total_score,
      "player_two_points" => player_two.total_score,
      "dealer_id" => safelyGetPlayerId(game.dealer),
      "pile_cards" => game.pile,
      "crib_cards" => game.crib,
      "cut_card" => game.cut_card,
      "whose_turn_id" => safelyGetPlayerId(game.whose_turn),
      "current_fsm_state" => game.fsm.aasm.current_state,
      "round" => game.round,
      "points_to_win" => game.points_to_win,
      "winner_id" => safelyGetPlayerId(game.winner)
    }
  end
end
