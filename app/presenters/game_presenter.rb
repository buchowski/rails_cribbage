class GamePresenter < SimpleDelegator
  attr_reader :player_name

  def initialize(game_model, player_name, your_previous_score, opponents_previous_score)
    @t = Proc.new do |key, data| Translations.en(key, data) end
    @game_model = game_model
    @game = Game.adapt_to_cribbage_game(game_model)
    @player_name = player_name
    # the previous scores are what the user last saw in the UI.
    # we diff against these to determine if we should alert the user that points were scored
    @your_previous_score = your_previous_score.nil? ? 0 : your_previous_score
    @opponents_previous_score = opponents_previous_score.nil? ? 0 : opponents_previous_score
    super(@game_model)
  end

  def game_play_message
    is_your_turn = @game.whose_turn.id == @player_name

    case @game.fsm.aasm.current_state
    when :playing
        is_your_turn ? @t.call("playing.you") : @t.call("playing.opponent")
    when :game_over
        @t.call("game.over")
    end
  end

  def game_play_alert
    alert = ""
    points_you_scored = player.total_score - @your_previous_score
    points_opponent_scored = opponent.total_score - @opponents_previous_score

    alert += @t.call("you.scored", {points: points_you_scored}) if points_you_scored > 0
    alert += @t.call("opponent.scored", {points: points_opponent_scored}) if points_opponent_scored > 0
    alert += @t.call("you.won") if you_won()
    alert += @t.call("opponent.won") if opponent_won()

    alert
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

  def is_game_over
    @game.fsm.aasm.current_state == :game_over
  end

  def is_the_winner(player_id)
    winner_id = @game.winner && @game.winner.id
    is_game_over && winner_id == player_id
  end

  def you_won
    is_the_winner(player.id)
  end

  def opponent_won
    is_the_winner(opponent.id)
  end

  def get_unplayed_cards(cards)
    unplayed = []

    cards.each_pair { |card, is_unplayed|
      unplayed << card if is_unplayed
    }

    unplayed
  end
end
