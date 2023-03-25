class GamePresenter < SimpleDelegator
  attr_reader :player_name

  def initialize(game_model, player_name, your_previous_score, opponents_previous_score)
    @t = Proc.new do |key, data| Translations.en(key, data) end
    @game_model = game_model
    @game = Game.adapt_to_cribbage_game(game_model)
    @player_name = player_name
    # the previous scores are what the user last saw in the UI.
    # we diff against these to determine if we should alert the user that points were scored
    @your_previous_score = your_previous_score
    @opponents_previous_score = opponents_previous_score
    super(@game_model)
  end

  def update_btn_content
    is_show_update_btn = true

    case current_state
    when :cutting_for_deal
      label = "Cut for deal"
      type_of_update = "cut_for_deal"
    when :dealing
      label = "Deal cards"
      type_of_update = "deal"
    when :waiting_for_player_two
      label = "Join game"
      type_of_update = "join_game"
    when :waiting_to_start
      label = "Start game"
      type_of_update = "start_game"
    else
      is_show_update_btn = false
    end

    return {
      is_show_update_btn: is_show_update_btn,
      label: label,
      type_of_update: type_of_update
    }
  end

  def game_play_message
    case current_state
    when :discarding
      hand_count = player && player.hand.values.size
      left_to_discard_count = hand_count - 4
      are_you_done_discarding = left_to_discard_count <= 0
      are_you_done_discarding ? @t.call("discarding.opponent", {opponent_name: opponent_name}) : @t.call("discarding.you", {card_count: left_to_discard_count})
    when :playing
      is_your_turn ? @t.call("playing.you") : @t.call("playing.opponent", {opponent_name: opponent_name})
    when :game_over
      @t.call("game.over")
    end
  end

  def game_play_alert
    alerts = []

    unless @your_previous_score.nil?
      points_you_scored = player_total_score - @your_previous_score
      alerts << @t.call("you.scored", {points: points_you_scored}) if points_you_scored > 0
    end

    unless @opponents_previous_score.nil?
      points_opponent_scored = opponent_total_score - @opponents_previous_score
      alerts << @t.call("opponent.scored", {points: points_opponent_scored}) if points_opponent_scored > 0
    end

    alerts << @t.call("you.won") if you_won()
    alerts << @t.call("opponent.won", {opponent_name: opponent_name}) if opponent_won()

    alerts.join(" ")
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

  def opponent_name
    name = opponent && opponent.id || ""
    name.capitalize
  end

  def player_name
    name = player && player.id || ""
    name.capitalize
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

  def player_total_score_percent
    player_total_score.to_f / @game.points_to_win * 100
  end

  def opponent_total_score_percent
    opponent_total_score.to_f / @game.points_to_win * 100
  end

  def pile_score
    @game.pile_score
  end

  def show_play_card_radios
    current_state == :playing
  end

  def show_discard_checkboxes
    current_state == :discarding
  end

  def show_refresh_btn
    !is_your_turn && current_state == :playing
  end

  def are_you_dealer
    if player && @game && @game.dealer
      return player.id == @game.dealer.id
    end
    false
  end

  def has_game_started
    case current_state
    when :waiting_for_player_two
      return false
    when :waiting_to_start
      return false
    else
      return true
    end
  end

  def labels
    return {
      welcome: @t.call("welcome", {player_name: player_name}),
      opponents_cards: @t.call("opponents.cards", {opponent_name: opponent_name}),
      you_have_n_points: @t.call("you_have_n_points", {points: player_total_score}),
      opponent_has_n_points: @t.call("opponent_has_n_points", {opponent_name: opponent_name, points: opponent_total_score}),
      your_crib: @t.call("your_crib"),
      opponents_crib: @t.call("opponents_crib", {opponent_name: opponent_name})
    }
  end

  private

  def is_game_over
    current_state == :game_over
  end

  def current_state
    @game.fsm.aasm.current_state
  end

  def is_the_winner(player_id)
    winner_id = @game.winner && @game.winner.id
    is_game_over && winner_id == player_id
  end

  def is_your_turn
    @game.whose_turn.id == @player_name
  end

  def you_won
    player && is_the_winner(player.id)
  end

  def opponent_won
    opponent && is_the_winner(opponent.id)
  end

  def get_unplayed_cards(cards)
    unplayed = []

    cards.each_pair { |card, is_unplayed|
      unplayed << card if is_unplayed
    }

    unplayed
  end
end
