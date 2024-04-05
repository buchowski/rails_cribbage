class AnonUser < User
  def name
    "Guest"
  end

  def id
    0
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
