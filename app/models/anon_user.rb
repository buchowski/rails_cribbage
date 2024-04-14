class AnonUser
  def name
    "Guest"
  end

  def self.id
    "guest"
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
end
