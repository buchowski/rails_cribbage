class GamesController < ApplicationController
  before_action :get_player, except: [:index]

  def index
    @games = Game.all
  end
  def show
    game_model = get_game_model()
    cribbage_game = get_cribbage_game(game_model)
    @cards = cribbage_game.players[0].hand
    @game = game_model
  end
  def create
    @game = Game.new(@player_name)

    if !@game.save
      flash[:error_msg] = "error: failed to save game"
    end
    redirect_to games_path
  end
  def update
    game_model = get_game_model()
    type_of_update = params[:type_of_update]

    begin
      if type_of_update == "join_game"
        join_game(game_model)
      elsif type_of_update == "start_game"
        start_game(game_model)
      else
        game = get_cribbage_game(game_model)

        case type_of_update
        when "cut_for_deal"
          game.cut_for_deal()
        when "deal"
          game.deal()
        when "discard"
          discard(game)
        end

        game_model.update(Game.adapt_to_active_record(game))
      end
    rescue => exception
      # truncate exception.message to prevent cookieoverflow
      flash[:error_msg] = exception.message[0, 100]
    ensure
      redirect_to game_path
    end
  end

  def destroy
    # todo only creator can delete game
    game = get_game_model()

    if !game.destroy
      flash[:error_msg] = "error: failed to delete game"
    end
    redirect_to games_path
  end

  private

  def get_game_model
    game_id = params[:id]
    Game.find(game_id)
  end

  def get_player
    @player_name = cookies[:player_name] || (params[:player_name] || "").strip

    throw "you must include your player_name in the request" if @player_name.empty? || @player_name.nil?

    cookies[:player_name] = @player_name
    @player_name
  end

  def join_game(game_model)
    player_one_name = game_model.player_one_id
    player_two_name = game_model.player_two_id

    if @player_name == player_one_name || @player_name == player_two_name
      throw "you already joined this game"
    end

    if player_two_name.nil?
      game_model.player_two_id = @player_name
      game_model.current_fsm_state = :waiting_to_start

      if !game_model.save then throw "failed to join game" end
    else
      throw "you're not allowed to join. too many players already"
    end
  end

  def start_game(game_model)
    if game_model.current_fsm_state.to_sym != :waiting_to_start
      throw "this game is either not ready to start or has been started already"
    end

    game_model.current_fsm_state = :cutting_for_deal

    if !game_model.save then throw "unable to start game" end
  end

  def get_cribbage_game(game_model)
    Game.adapt_to_cribbage_game(game_model)
  end

  def discard(game)
    cards = params[:cards] || []
    # todo remove hardcoded player
    player = game.players[0]
    discarded_cards = player.hand.values
    num_of_cards_to_discard = discarded_cards.size - 4

    if num_of_cards_to_discard <= 0
      throw "You may not discard any more cards"
    elsif num_of_cards_to_discard == 1 && cards.size != 1
      throw "You may only discard one more card"
    elsif cards.size > 2
      throw "You may only discard two cards"
    elsif cards.size == 0
      throw "You must select one or two cards to discard"
    end

    cards.each { |card_id| game.discard(player, card_id) }
  end
end
