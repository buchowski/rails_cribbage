class AnonGamePresenter < GamePresenter

  def initialize(game_model)
    player_name = game_model.player_one_id
    your_previous_score = 0
    opponents_previous_score = 0
    super(game_model, player_name, your_previous_score, opponents_previous_score)
  end

  def are_you_anonymous
    true
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
