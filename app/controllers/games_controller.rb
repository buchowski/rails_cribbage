class GamesController < ApplicationController
  before_action :get_game, except: [:index, :create, :cards]
  before_action :get_player_name
  before_action :require_player_name, except: [:index, :show, :cards]

  def index
    @games = Game.all
  end

  def show
    if is_user_anonymous
      @game = AnonGamePresenter.new(@game_model, @player_name)
    else
      @game = GamePresenter.new(@game_model, @player_name, flash[:your_score], flash[:opponents_score])
    end
  end

  def create
    begin
      new_game = Game.new(@player_name)

      if !new_game.save
        flash[:error_msg] = "error: failed to save game"
      end
    rescue => exception
      flash[:error_msg] = exception.message[0, 100]
    ensure
      redirect_to games_path
    end
  end

  def update
    type_of_update = params[:type_of_update]
    your_score = player && player.total_score
    opponents_score = opponent && opponent.total_score

    begin
      if type_of_update == "join_game"
        join_game()
      elsif type_of_update == "start_game"
        start_game()
      else
        check_membership()

        case type_of_update
        when "cut_for_deal"
          @game.cut_for_deal()
        when "deal"
          @game.deal()
        when "discard"
          discard()
        when "play_card"
          play_card()
          # if all cards have been played then we score the hands and crib
          if @game.fsm.scoring_opponent_hand?
            score_hands_and_crib()
          end
        end

        @game_model.update(Game.adapt_to_active_record(@game))
      end
    rescue => exception
      # truncate exception.message to prevent cookieoverflow
      flash[:error_msg] = exception.message[0, 100]
    ensure
      redirect_to game_path, flash: { your_score: your_score, opponents_score: opponents_score }
    end
  end

  def destroy
    begin
      check_membership()
      # todo only creator can delete game
      if !@game_model.destroy
        flash[:error_msg] = "error: failed to delete game"
      end
    rescue => exception
        flash[:error_msg] = exception.message[0, 100]
    ensure
      redirect_to games_path
    end
  end

  def cards
    render "cards/cards_preview"
  end

  private

  def get_game
    @game_model = get_game_model()
    @game = get_cribbage_game(@game_model)
  end

  def get_game_model
    game_id = params[:id]
    Game.find(game_id)
  end

  def get_cribbage_game(game_model)
    Game.adapt_to_cribbage_game(game_model)
  end

  def check_membership
    is_player_one = @player_name == @game_model.player_one_id
    is_player_two = @player_name == @game_model.player_two_id
    is_member = is_player_one || is_player_two

    if !is_member
      throw "You are not a member of this game"
    end
  end

  def get_player_name
    @player_name = cookies[:player_name]
  end

  def require_player_name
    if @player_name.nil? || @player_name.empty?
      flash[:error_msg] = "you must include your player_name in the request"
      redirect_to request.env['HTTP_REFERER']
      return
    end
  end

  def player
    return if @game_model.nil? || @player_name.nil?

    is_player_one = @player_name == @game_model.player_one_id
    is_player_two = @player_name == @game_model.player_two_id

    return @game.players[0] if is_player_one
    return @game.players[1] if is_player_two
  end

  def opponent
    return nil if !player

    @game.players.find{ |p| p.id != player.id }
  end

  def is_user_anonymous
    !@player_name || (@player_name != @game_model.player_one_id && @player_name != @game_model.player_two_id)
  end

  def join_game()
    player_one_name = @game_model.player_one_id
    player_two_name = @game_model.player_two_id

    if @player_name == player_one_name || @player_name == player_two_name
      throw "you already joined this game"
    end

    if player_two_name.nil?
      @game_model.player_two_id = @player_name
      @game_model.current_fsm_state = :waiting_to_start

      if !@game_model.save then throw "failed to join game" end
    else
      throw "you're not allowed to join. too many players already"
    end
  end

  def start_game()
    if @game_model.current_fsm_state.to_sym != :waiting_to_start
      throw "this game is either not ready to start or has been started already"
    end

    @game_model.current_fsm_state = :cutting_for_deal

    if !@game_model.save then throw "unable to start game" end
  end

  def discard()
    cards = params[:cards] || []
    cards_in_hand = player.hand.keys
    num_of_cards_to_discard = cards_in_hand.size - 4

    if num_of_cards_to_discard <= 0
      throw "You may not discard any more cards"
    elsif num_of_cards_to_discard == 1 && cards.size == 0
      throw "You must select one more card to discard"
    elsif cards.size == 0
      throw "You must select one or two cards to discard"
    elsif num_of_cards_to_discard == 1 && cards.size != 1
      throw "You may only discard one more card"
    elsif cards.size > 2
      throw "You may only discard two cards"
    end

    cards.each { |card_id| @game.discard(player, card_id) }

    # automatically flip the top card. no need for manual user action
    @game.flip_top_card if @game.fsm.flipping_top_card?
  end

  def play_card()
    card_id = params[:card_to_play]

    if card_id.nil? || card_id.empty?
      throw "you must select a card to play"
    end

    @game.play_card(player, card_id)
  end

  def score_hands_and_crib()
    begin
      @game.submit_hand_scores(@game.opponent)
      @game.submit_hand_scores(@game.dealer)
      @game.submit_crib_scores()
    rescue => exception
      throw exception unless @game.fsm.game_over?
    end
  end
end
