class GamesController < ApplicationController
  before_action :get_game, except: [:index, :create]
  before_action :get_player, except: [:index]

  def index
    @games = Game.all
  end

  def show
    @game = @game_model
    @cards = @player.nil? ? {} : @player.hand
  end

  def create
    Game.new(@player_name)

    if !@game.save
      flash[:error_msg] = "error: failed to save game"
    end
    redirect_to games_path
  end

  def update
    type_of_update = params[:type_of_update]

    begin
      if type_of_update == "join_game"
        join_game()
      else
        check_membership()
      end

      case type_of_update
      when "start_game"
        start_game()
      when "cut_for_deal"
        @game.cut_for_deal()
      when "deal"
        @game.deal()
      when "discard"
        discard()
      end

      @game_model.update(Game.adapt_to_active_record(@game))
    rescue => exception
      # truncate exception.message to prevent cookieoverflow
      flash[:error_msg] = exception.message[0, 100]
    ensure
      redirect_to game_path
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
    params_player_name = (params[:player_name] || "").strip
    do_names_match = params_player_name == cookies[:player_name]

    if !do_names_match && params_player_name.present?
      cookies[:player_name] = params_player_name
    end

    @player_name = cookies[:player_name]

    throw "you must include your player_name in the request" if @player_name.nil? || @player_name.empty?
  end

  def get_player
    get_player_name()
    is_player_one = @player_name == @game_model.player_one_id
    is_player_two = @player_name == @game_model.player_two_id

    @player = @game.players[0] if is_player_one
    @player = @game.players[1] if is_player_two
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
    cards_in_hand = @player.hand.keys
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

    cards.each { |card_id| @game.discard(@player, card_id) }
  end
end
