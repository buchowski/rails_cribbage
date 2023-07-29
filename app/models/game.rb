class Game < ApplicationRecord
  validates :player_one_id, presence: true
  serialize :player_one_cards, Hash
  serialize :player_two_cards, Hash
  serialize :pile_cards, Array
  serialize :crib_cards, Array

  def initialize(creator_id)
    cribbage_game = CribbageGame::Game.new
    adapted_game = self.class.adapt_to_active_record(cribbage_game)

    adapted_game[:player_one_id] = creator_id
    adapted_game[:player_two_id] = nil
    adapted_game[:current_fsm_state] = :waiting_for_player_two

    super(adapted_game);
  end

  def get_stream_id_for_user(user)
    user.is_member(self) ? "#{user.id}-#{self.id}" : "guest-#{self.id}"
  end

  private

  def self.safely_get_id entity
    entity ? entity.id : nil
  end

  def self.adapt_to_active_record(game)
    player_one = game.players[0]
    player_two = game.players[1]

    {
      "player_one_id" => player_one.id,
      "player_two_id" => player_two.id,
      "player_one_cards" => player_one.hand,
      "player_two_cards" => player_two.hand,
      "player_one_points" => player_one.total_score,
      "player_two_points" => player_two.total_score,
      "dealer_id" => self.safely_get_id(game.dealer),
      "pile_cards" => game.pile,
      "crib_cards" => game.crib,
      "cut_card" => game.cut_card,
      "whose_turn_id" => self.safely_get_id(game.whose_turn),
      "current_fsm_state" => game.fsm.aasm.current_state,
      "round" => game.round,
      "points_to_win" => game.points_to_win,
      "winner_id" => self.safely_get_id(game.winner)
    }
  end

  def self.get_winner(winner_id, player_one, player_two)
    return nil if winner_id.nil?

    return winner_id == player_one.id ? player_one : player_two
  end

  def self.are_users_valid(game_model, user_one, user_two)
    return false if safely_get_id(user_one) != game_model.player_one_id
    return false if safely_get_id(user_two) != game_model.player_two_id
    return true
  end

  def self.adapt_to_cribbage_game(game_model, user_one, user_two)
    game = CribbageGame::Game.new
    player_one = game.players[0]
    player_two = game.players[1]

    throw "users do not match game.players" if !self.are_users_valid(game_model, user_one, user_two)

    player_one.id = game_model.player_one_id
    player_one.hand = game_model.player_one_cards
    player_one.total_score = game_model.player_one_points
    player_one.name = user_one.nil? ? "" : user_one.name
    player_two.id = game_model.player_two_id
    player_two.hand = game_model.player_two_cards
    player_two.total_score = game_model.player_two_points
    player_two.name = user_two.nil? ? "" : user_two.name

    is_player_one_dealer = game_model.dealer_id == game_model.player_one_id
    game.dealer = is_player_one_dealer ? player_one : player_two
    is_player_one_turn = game_model.whose_turn_id == game_model.player_one_id
    game.whose_turn = is_player_one_turn ? player_one : player_two
    game.winner = self.get_winner(game_model.winner_id, player_one, player_two)

    game.fsm.aasm.current_state = game_model.current_fsm_state.to_sym
    game.round = game_model.round
    game.points_to_win = game_model.points_to_win

    game.pile = game_model.pile_cards
    game.crib = game_model.crib_cards
    game.cut_card = game_model.cut_card

    game
  end
end
