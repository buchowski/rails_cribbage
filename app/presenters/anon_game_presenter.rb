class AnonGamePresenter < GamePresenter

  def initialize(game_model, player_name)
    @anon_users_name = player_name
    your_previous_score = 0
    opponents_previous_score = 0
    super(game_model, game_model.player_one_id, your_previous_score, opponents_previous_score)
  end

  def are_you_anonymous
    true
  end

  def welcome_msg
    @t.call("welcome", {player_name: @anon_users_name})
  end

  def crib_label
    crib_owners_name = are_you_dealer ? player_name : opponent_name

    return @t.call("player_crib", {player_name: crib_owners_name})
  end

  def player_has_n_points_label
    @t.call("player_has_n_points", {player_name: player_name, points: player_total_score})
  end

  def game_play_message
    "take a walk on the wildside"
  end

  def game_play_alert
    nil
  end

  def show_play_card_radios
    false
  end

  def show_discard_checkboxes
    false
  end

  def show_refresh_btn
    false
  end
end
