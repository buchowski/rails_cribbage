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
    player.nil? ? [] : get_unplayed_cards(player.hand)
  end

  def opponent_cards
    opponent.nil? ? [] : get_unplayed_cards(opponent.hand)
  end

  def player_total_score
    player.nil? ? 0 : player.total_score
  end

  def opponent_total_score
    opponent.nil? ? 0 : opponent.total_score
  end

  def pile_score
    @game.pile_score
  end

  def should_show_play_card_radios
    @game.fsm.aasm.current_state == :playing
  end

  def should_show_discard_checkboxes
    @game.fsm.aasm.current_state == :discarding
  end

  private

  def get_unplayed_cards(cards)
    unplayed = []

    cards.each_pair { |card, is_unplayed|
      unplayed << card if is_unplayed
    }

    unplayed
  end
end
