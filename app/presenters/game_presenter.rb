class GamePresenter < SimpleDelegator
  attr_reader :player_name

  def initialize(game_model, player_name)
    @game_model = game_model
    @game = Game.adapt_to_cribbage_game(game_model)
    @player_name = player_name
    super(@game_model)
  end

  def player
    is_player_one = @player_name == @game_model.player_one_id
    is_player_two = @player_name == @game_model.player_two_id

    return @game.players[0] if is_player_one
    return @game.players[1] if is_player_two
  end

  def opponent
    return nil if player.nil?

    is_player_one = @player_name == @game_model.player_one_id
    is_player_one ? @game.players[1] : @game.players[0]
  end

  def player_cards
    return [] if player.nil?

    player.hand
  end

  def opponent_cards
    return [] if opponent.nil?

    opponent.hand
  end

  def pile_score
    @game.pile_score
  end
end
