class GamePresenter < SimpleDelegator
  attr_reader :player_name, :play_by_play

  def initialize(game_model, cribbage_game, user, play_by_play, is_bot_game = false)
    @t = Proc.new do |key, data| Translations.en(key, data) end
    @game = cribbage_game
    @user = user
    @play_by_play = (play_by_play || []).map do |msg|
      msg.class == String ? {text: msg, id: nil} : msg
    end
    @is_bot_game = is_bot_game

    adapted_game = Game.adapt_to_active_record(cribbage_game)
    # dirty means this model contains data that may not yet be persisted in the database
    dirty_game_model = Game.new(adapted_game)
    dirty_game_model.assign_attributes(
      id: game_model.id,
      updated_at: game_model.updated_at,
      created_at:  game_model.created_at
    )

    super(dirty_game_model)
  end

  # TODO we're currently not using this
  def self.format_cards_in_msg(msg)
    suit_map = {"h" => "&hearts;", "d" => "&diams;", "c" => "&clubs;", "s" => "&spades;"}
    msg.gsub(/[ 1]{1}[0-9qkaj]{1}[hdcs]{1}/) do |card_id|
      suit = card_id.last
      "<span>" + card_id[0..-2].upcase + suit_map[suit] + "</span>"
    end
  end

  def crib_label
    return "Dealer's crib" if @game.dealer.nil?
    are_you_dealer ? @t.call("your_crib") : @t.call("player_crib", {player_name: opponent_name})
  end

  def who_is_the_dealer
    return if @game.dealer.nil?
    are_you_dealer ? "You are the dealer" : "#{opponent_name} is the dealer"
  end

  def player_has_n_points_label
    @t.call("you_have_n_points", {points: player_total_score})
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
      if is_user_creator
        is_show_update_btn = false
      else
      label = "Join game"
      type_of_update = "join_game"
      end
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
    when :cutting_for_deal
      'Click "Cut for deal" to see who deals first'
    when :dealing
      are_you_dealer ? "Deal the cards" : "Deal the cards on #{opponent_name}'s behalf"
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

  def is_user_creator
    self.player_one_id == @user.id
  end

  # this is the creator
  def player_one_name
    player = @game.players[0]
    player ? player.name : 'unnamed'
  end

  # this is the player who joined
  def player_two_name
    player = @game.players[1]
    player ? player.name : 'unnamed'
  end

  # this is the authenticated user
  def player
    is_user_player_two = @user.id == self.player_two_id

    return is_user_player_two ? @game.players[1] : @game.players[0]
  end

  # this is the authenticated user's opponent
  def opponent
    is_user_player_two = @user.id == self.player_two_id

    return is_user_player_two ? @game.players[0] : @game.players[1]
  end

  def opponent_name
    opponent.name.capitalize
  end

  def player_name
    player.name.capitalize
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

  def pile_cards_formatted
    self.pile_cards
  end

  def show_play_card_radios
    current_state == :playing && self.player_cards.size > 0
  end

  def show_discard_checkboxes
    current_state == :discarding
  end

  def show_refresh_btn
    !is_your_turn && current_state == :playing && @is_bot_game
  end

  def show_join_link
    current_state == :waiting_for_player_two && is_user_creator
  end

  def are_you_dealer
    if player && @game && @game.dealer
      return player.id == @game.dealer.id
    end
    false
  end

  def is_opponent_dealer
    if opponent && @game && @game.dealer
      return opponent.id == @game.dealer.id
    end
    false
  end

  def are_you_anonymous
    false
  end

  def have_cards_been_dealt
    ![:waiting_for_player_two, :waiting_to_start, :cutting_for_deal, :dealing].include? current_state
  end

  def has_game_started
    ![:waiting_for_player_two, :waiting_to_start].include? current_state
  end

  def crib_cards_section_class
    are_you_dealer ? "players_crib" : "opponents_crib"
  end

  def opponent_cards_section_header
    header = "#{opponent_name}'s cards"
    is_opponent_dealer ? header + " (Dealer)" : header
  end

  def your_cards_section_header
    header = are_you_anonymous ? "#{player_name}'s cards" : "Your cards"
    are_you_dealer ? header + " (Dealer)" : header
  end

  def labels
    return {
      opponent_has_n_points: @t.call("player_has_n_points", {player_name: opponent_name, points: opponent_total_score}),
      your_crib: @t.call("your_crib"),
      player_crib: @t.call("player_crib", {player_name: player_name}),
      opponents_crib: @t.call("player_crib", {player_name: opponent_name})
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
    @game.whose_turn.id == player.id
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
