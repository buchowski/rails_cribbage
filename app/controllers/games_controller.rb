class GamesController < ApplicationController
  before_action :get_game, except: [:index, :create, :cards, :admin]
  before_action :require_user_id, except: [:index, :show, :cards, :admin]

  include BotLogic
  include Broadcast

  def initialize
    @your_play_by_play = []
    @their_play_by_play = []
    super()
  end

  def index
    game_models = Game.where(player_one_id: @user.id).or(Game.where(player_two_id: @user.id))
    games = get_game_presenters(game_models)
    bots = User.where(is_bot: true)
    render "games/index", locals: { gvms: games, bots: bots }
  end

  def admin
    users = User.all
    games = get_game_presenters(Game.all)
    render "games/admin", locals: { gvms: games, users: users }
  end

  def game_view_model(game = @game)
    if @user.is_member(@game_model)
      return GamePresenter.new(@game_model, game, @user, @your_play_by_play)
    else
      return AnonGamePresenter.new(@game_model, game, @user, @their_play_by_play)
    end
  end

  def show
    @your_play_by_play = flash[:your_play_by_play] || []
    gvm = game_view_model()
    render "games/show", { locals: { gvm: gvm, app: @app, user: @user } }
  end

  def create
    bot_id = params[:bot_id]
    bot = User.find_by_id(bot_id) if !bot_id.nil?

    begin
      cribbage_game = CribbageGame::Game.new
      adapted_game = Game.adapt_to_active_record(cribbage_game)
      adapted_game[:player_one_id] = @user.id
      adapted_game[:player_two_id] = nil
      adapted_game[:current_fsm_state] = :waiting_for_player_two

      if !bot.nil?
        adapted_game[:player_two_id] = bot.id
        adapted_game[:current_fsm_state] = :cutting_for_deal
      end

      new_game = Game.new(adapted_game)

      if !new_game.save
        flash[:error_msg] = "error: failed to save game"
      end
    rescue StandardError => exception
      flash[:error_msg] = exception.message[0, 100]
    ensure
      redirect_to games_path
    end
  end

  def update
    type_of_update = params[:type_of_update]

    begin
      if type_of_update == "join_game"
        join_game()
      elsif type_of_update == "start_game"
        check_membership()
        start_game()
      else
        check_membership()

        add_score_to_play_by_play(@player) do
          case type_of_update
          when "cut_for_deal"
            cut_for_deal()
          when "deal"
            deal()
          when "discard"
            discard()
          when "play_card"
            play_card()
          when "hurry_up_bot"
            get_bot_unstuck();
          end
        end

        if is_single_player_game && type_of_update != "hurry_up_bot"
          pre_bot_update_html_string = render_to_string(
            partial: "games/game_play_container",
            locals: {
              gvm: game_view_model,
              app: @app
            }
          )

          add_score_to_play_by_play(@opponent) do
            # TODO it may still be the bot's turn after the bot plays a card. need to check
            update_game_with_bot_move(type_of_update)
          end
        end

        # if all cards have been played then we score the hands and crib
        if @game.fsm.scoring_opponent_hand?
          score_hands_and_crib()
        end

        @game_model.update(Game.adapt_to_active_record(@game))
      end

      # after we update @game_model, ensure the rest of the instance vars are up to date
      set_instance_vars()

      if is_broadcast_to_opponent
        broadcast_to_opponent()
      end

      broadcast_to_guests()
    # TODO improve error handling. remove "uncaught..." from error msg we render in UI
    rescue StandardError => exception
      # truncate exception.message to prevent cookieoverflow
      flash[:error_msg] = exception.message[0, 100]
    ensure
      respond_to do |format|
        format.turbo_stream {
          flash.discard(:error_msg)
          render(
            partial: "games/update",
            locals: {
              gvm: game_view_model,
              pre_bot_update_html_string: pre_bot_update_html_string,
              app: @app
            }
          )
        }
        format.html {
          redirect_to game_path,
          flash: { your_play_by_play: @your_play_by_play }
        }
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
    rescue StandardError => exception
        flash[:error_msg] = exception.message[0, 100]
    ensure
      redirect_to games_path
    end
  end

  def cards
    render "cards/cards_png_preview"
  end

  private

  def is_single_player_game
    !@opponent_user.nil? && @opponent_user.is_bot
  end

  def is_broadcast_to_opponent
    !@opponent_user.nil? && !@opponent_user.is_bot
  end

  def get_game_presenters(game_models)
    empty_play_by_play = []
    game_models.map do |game_model|
      game = get_cribbage_game(game_model)
      AnonGamePresenter.new(game_model, game, @user, empty_play_by_play)
    end
  end

  def get_game
    @game_model = Game.find_by_id(params[:id])

    # TODO how to properly handle 404?
    throw "sorry can't find that game" if @game_model.nil?

    set_instance_vars()
  end

  def set_instance_vars
    @game = get_cribbage_game(@game_model)

    is_user_player_two = @user.id == @game_model.player_two_id

    @player = is_user_player_two ? @game.players[1] : @game.players[0]
    @opponent = is_user_player_two ? @game.players[0] : @game.players[1]
    @opponent_user = @opponent.nil? ? nil : User.find_by_id(@opponent.id)
  end

  def get_cribbage_game(game_model)
    Game.adapt_to_cribbage_game(game_model)
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
    @your_play_by_play.concat(["You have started the game", "Cut cards to see who deals first"])
    @their_play_by_play.concat(["#{@user.name} has started the game", "Cut cards to see who deals first"])
  end

  def deal()
    throw "You are not the dealer" unless @user.is_dealer(@game_model) || is_single_player_game
    @game.deal()
    # TODO it's possible the bot was the actual dealer
    @your_play_by_play << "You have dealt the cards"
    @their_play_by_play << "#{@user.name} has dealt the cards"
  end

  def cut_for_deal()
    # TODO only allow creator to perform deal? wait for both players to cut?
    @game.cut_for_deal()
    are_you_the_dealer = @game.dealer.id == @user.id
    dealer = are_you_the_dealer ? @user : @opponent_user
    whose_turn = are_you_the_dealer ? @opponent_user : @user

    you_are_the_dealer_msgs = ["You are the dealer", "It is #{whose_turn.name}'s turn to play"]
    they_are_the_dealer_msgs = ["#{dealer.name} is the dealer", "It is your turn to play"]

    # TODO show which cards the players cut?
    if are_you_the_dealer
      @your_play_by_play.concat(you_are_the_dealer_msgs)
      @their_play_by_play.concat(they_are_the_dealer_msgs)
    else
      @your_play_by_play.concat(they_are_the_dealer_msgs)
      @their_play_by_play.concat(you_are_the_dealer_msgs)
    end
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

    @your_play_by_play << "You have discarded #{cards.size} card(s): #{cards.join(', ')}"
    @their_play_by_play << "#{@user.name} has discarded #{cards.size} card(s)"

    # automatically flip the top card. no need for manual user action
    if @game.fsm.flipping_top_card?
      @game.flip_top_card
      msg = "#{@game.cut_card} was auto-selected as the cut card"
      @your_play_by_play << msg
      @their_play_by_play << msg
    end
  end

  def play_card()
    card_id = params[:card_to_play]

    if card_id.nil? || card_id.empty?
      throw "you must select a card to play"
    end

    @game.play_card(@player, card_id)
    @your_play_by_play << "You played a #{card_id}"
    @their_play_by_play << "#{@user.name} played a #{card_id}"
  end

  def score_hands_and_crib()
    are_you_the_dealer = @game.dealer.id == @user.id
    is_log_zero_score = true
    begin
      add_score_to_play_by_play(@game.opponent, is_log_zero_score) do
        cards = "#{@game.opponent.hand.keys.join(', ')} + cut: #{@game.cut_card}"
        their_msg = "Scoring #{@game.opponent.name}'s hand: #{cards}"
        msg = are_you_the_dealer ? their_msg : "Scoring your hand: #{cards}"
        @your_play_by_play << msg
        @their_play_by_play << their_msg

        @game.submit_hand_scores(@game.opponent)
      end

      add_score_to_play_by_play(@game.dealer, is_log_zero_score) do
        cards = "#{@game.dealer.hand.keys.join(', ')} + cut: #{@game.cut_card}"
        their_msg = "Scoring #{@game.dealer.name}'s hand: #{cards}"
        msg = are_you_the_dealer ? "Scoring your hand: #{cards}" : their_msg
        @your_play_by_play << msg
        @their_play_by_play << their_msg

        @game.submit_hand_scores(@game.dealer)
      end

      # crib belongs to the dealer
      add_score_to_play_by_play(@game.dealer, is_log_zero_score) do
        cards = "#{@game.crib.join(', ')} + cut: #{@game.cut_card}"
        their_msg = "Scoring #{@game.dealer.name}'s crib: #{cards}"
        msg = are_you_the_dealer ? "Scoring your crib: #{cards}" : their_msg
        @your_play_by_play << msg
        @their_play_by_play << their_msg

        @game.submit_crib_scores()
      end
    rescue StandardError => exception
      throw exception unless @game.fsm.game_over?
    end
  end

  def add_score_to_play_by_play(player, is_log_zero_score = false)
    before_score = player.total_score
    yield
    score_diff = player.total_score - before_score
    is_scoring_for_opponent = player.id == @opponent.id

    return if score_diff == 0 && !is_log_zero_score

    their_msg = "#{player.name} scored #{score_diff} points"
    your_msg = "You scored #{score_diff} points"

    if score_diff === 1
      their_msg = "#{player.name} scored one point"
      your_msg = "You scored one point"
    end

    @their_play_by_play << their_msg
    msg = is_scoring_for_opponent ? their_msg : your_msg
    @your_play_by_play << msg
  end
end
