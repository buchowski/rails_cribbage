class AnonUser
  def name
    "Guest"
  end

  def self.id
    0
  end

  def id
    AnonUser.id
  end

  def is_anon?
    true
  end

  def is_admin?
    false
  end

  def games
    []
  end

  def is_member(game_model)
    false
  end

  def is_dealer(game_model)
    # TODO it's possible for an anon user to be a dealer in a quick_game
    false
  end
end
