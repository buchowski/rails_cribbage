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
      playable_card = nil
      @opponent.hand.each_pair do |card_id, is_playable|
       if is_playable && @game.can_play_card?(card_id)
        playable_card = card_id
       end
      end

      if playable_card
        @game.play_card(@opponent, playable_card)
        play_msg = "#{@opponent.name} played #{playable_card}"
        @your_play_by_play << play_msg
        @their_play_by_play << play_msg
      end
    end

    def get_bot_unstuck
      throw "This is not a bot game" if !is_single_player_game
      throw "It's not the bot's turn" if !is_bots_turn
      if @game.fsm.discarding?
        type_of_update = "discard"
      elsif @game.fsm.playing?
        type_of_update = "play_card"
      end

      update_game_with_bot_move(type_of_update)
    end

    def is_bots_turn
      @game.whose_turn.id == @opponent.id
    end

    def discard_bot_cards
      bot_cards = @opponent.hand.keys

      return if bot_cards.size <= 4

      cards_to_discard = bot_cards[0..1]
      cards_to_discard.each { |card_id| @game.discard(@opponent, card_id) }

      discard_msg = "#{@opponent.name} has discarded #{cards_to_discard.size} cards"
      @your_play_by_play << discard_msg
      @their_play_by_play << discard_msg

      if @game.fsm.flipping_top_card?
        @game.flip_top_card
        top_card_msg = "#{@game.cut_card} was auto-selected as the cut card"
        @your_play_by_play << top_card_msg
        @their_play_by_play << top_card_msg
      end

      play_bot_card() if is_bots_turn
    end

    def has_player_discarded_all_cards
      cards_in_hand = @player.hand.keys
      num_of_cards_to_discard = cards_in_hand.size - 4
      num_of_cards_to_discard <= 0
    end
  end
end
