class AnonUser
  def name
    "Guest"
  end

  def id
    "ANON"
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
