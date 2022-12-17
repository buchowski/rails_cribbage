module GameService
  class GameMash < CribbageGame::Game
    attr_reader :game_model

    delegate :id, :created_at, :player_one_id, :player_two_id, :current_fsm_state, :attributes, to: :game_model

    def initialize(game_model)
      # attr_accessor :players, :deck, :crib, :pile, :cut_card, :dealer, :whose_turn, :fsm, :points_to_win, :round
      @game_model = game_model
      super()
    end
  end

  def GameService.new(creator_id)
    @game_model = Game.new(creator_id)

    self.getGame(@game_model)
  end
  def GameService.find(game_id)
    @game_model = Game.find(game_id)

    self.getGame(@game_model)
  end
  def GameService.all
    Game.all.map  { |game_model| self.getGame(game_model) }
  end
  def self.getFsmStartState
    CribbageGame::Game.new.fsm.aasm.current_state
  end

  def GameService.getGame(game_model)
    GameMash.new(game_model)
  end
end

