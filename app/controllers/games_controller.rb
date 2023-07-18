class GamesController < ApplicationController
  before_action :get_game, except: [:index, :create, :cards, :admin]
  before_action :require_user_id, except: [:index, :show, :cards, :admin]

  def index
    game_models = Game.where(player_one_id: @user.id).or(Game.where(player_two_id: @user.id))
    @games = get_game_presenters(game_models)
  end

  def admin
    @users = User.all
    @games = get_game_presenters(Game.all)
  end

  def game_view_model
    if @user.is_member(@game_model)
      return GamePresenter.new(@game_model, @game, @user, flash[:your_score], flash[:opponents_score])
    else
      return AnonGamePresenter.new(@game_model, @game, @user)
    end
  end

  def show
    @game = game_view_model()
  end

  def create
    begin
      new_game = Game.new(@user.id)

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
        check_membership()
        start_game()
      else
        # TODO only allow creator to perform cut_for_deal & deal?
        # perform these actions as part of start_game?
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
    # TODO improve error handling. remove "uncaught..." from error msg we render in UI
    rescue StandardError => exception
      # truncate exception.message to prevent cookieoverflow
      flash[:error_msg] = exception.message[0, 100]
    ensure
      respond_to do |format|
        format.turbo_stream {
          flash.discard(:error_msg)

          # TODO @game has two different meanings (get_game vs game_view_model). clean up
          @game = game_view_model()
          render turbo_stream: turbo_stream.replace(helpers.dom_id(@game_model), partial: "games/game_play_container")
        }
        format.html { redirect_to game_path, flash: { your_score: your_score, opponents_score: opponents_score } }
      end
    end
  end

  def destroy
    begin
      if !@user.is_creator(@game_model)
        flash[:error_msg] = "Only the game creator can delete this game"
      elsif !@game_model.destroy
        flash[:error_msg] = "error: failed to delete game"
      end
    rescue => exception
        flash[:error_msg] = exception.message[0, 100]
    ensure
      redirect_to games_path
    end
  end

  def cards
    render "cards/cards_png_preview"
  end

  private

  def get_game_presenters(game_models)
    game_models.map do |game_model|
      game = get_cribbage_game(game_model)
      AnonGamePresenter.new(game_model, game, @user)
    end
  end

  def get_game
    @game_model = get_game_model()

    # TODO how to properly handle 404?
    throw "sorry can't find that game" if @game_model.nil?

    @game = get_cribbage_game(@game_model)
  end

  def get_game_model
    game_id = params[:id]
    Game.find_by_id(game_id)
  end

  def get_cribbage_game(game_model)
    user_one = User.find_by_id(game_model.player_one_id)
    user_two = User.find_by_id(game_model.player_two_id)

    Game.adapt_to_cribbage_game(game_model, user_one, user_two)
  end

  def check_membership
    if !@user.is_member(@game_model)
      throw "You are not a member of this game"
    end
  end

  def require_user_id
    if @user.is_anon?
      flash[:error_msg] = "you must must log in before you're able to play"
      redirect_to request.env['HTTP_REFERER'] || games_path
      return
    end
  end

  def player
    return if @game_model.nil?

    is_user_player_two = @user.id == @game_model.player_two_id

    return is_user_player_two ? @game.players[1] : @game.players[0]
  end

  def opponent
    return if @game_model.nil?

    is_user_player_two = @user.id == @game_model.player_two_id

    return is_user_player_two ? @game.players[0] : @game.players[1]
  end

  def join_game()
    player_one_id = @game_model.player_one_id
    player_two_id = @game_model.player_two_id

    if @user.id == player_one_id || @user.id == player_two_id
      throw "you already joined this game"
    end

    if player_two_id.nil?
      @game_model.player_two_id = @user.id
      @game_model.current_fsm_state = :waiting_to_start

      if !@game_model.save then throw "failed to join game" end
    else
      throw "you're not allowed to join. too many players already"
    end
  end

  def start_game()
    if @game_model.current_fsm_state.to_sym != :waiting_to_start
      throw "this game is either not ready to start or has been started already"
    elsif !@user.is_creator(@game_model)
      throw "Only the game creator can start the game"
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
