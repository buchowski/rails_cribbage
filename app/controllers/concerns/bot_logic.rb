module BotLogic
  extend ActiveSupport::Concern

  included do

    def update_game_with_bot_move(type_of_update)
      case type_of_update
      when "cut_for_deal"
        # player has already cut
        @game.deal()
      when "discard"
        discard_bot_cards() if has_player_discarded_all_cards()
      when "play_card"
        play_bot_card()
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

      return if bot_cards.size <= 4

      cards_to_discard = bot_cards[0..1]
      cards_to_discard.each { |card_id| @game.discard(@opponent, card_id) }
      @game.flip_top_card if @game.fsm.flipping_top_card?
    end

    def has_player_discarded_all_cards
      cards_in_hand = @player.hand.keys
      num_of_cards_to_discard = cards_in_hand.size - 4
      num_of_cards_to_discard <= 0
    end
  end
end
