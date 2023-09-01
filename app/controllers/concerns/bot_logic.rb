module BotLogic
  extend ActiveSupport::Concern

  included do

    def update_game_with_bot_move()
      case @game.fsm.aasm.current_state
      when :discarding
        discard_bot_cards()
      when :playing
        is_bots_turn = @game.whose_turn.id == @opponent.id

        play_bot_card() if is_bots_turn
      end
    end

    def play_bot_card
      playable_card = @opponent.hand.keys.find do |card_id|
        @game.can_play_card?(card_id)
      end
      @game.play_card(@opponent, playable_card)
    end

    def discard_bot_cards
      bot_cards = @opponent.hand.keys

      return if bot_cards.size == 4

      cards_to_discard = bot_cards[0..1]
      cards_to_discard.each { |card_id| @game.discard(@opponent, card_id) }
      @game.flip_top_card if @game.fsm.flipping_top_card?
    end

  end

end
