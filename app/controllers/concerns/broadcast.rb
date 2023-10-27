module Broadcast
  extend ActiveSupport::Concern

  included do
    def broadcast_to_opponent()
      opponent_gvm = GamePresenter.new(
        @game_model,
        @game,
        @opponent_user,
        @their_play_by_play,
        @is_bot_game
      )
      opponent_stream_id = opponent_gvm.get_stream_id_for_user(@opponent_user)

      Turbo::StreamsChannel.broadcast_render_to(
        opponent_stream_id,
        partial: "games/update",
        locals: {
          gvm: opponent_gvm,
          pre_bot_update_html_string: nil,
          app: AppPresenter.new(@opponent_user)
        }
      )
    end
  end

  def broadcast_to_guests
    # if any guests are watching the game, update their views
    anon_user = AnonUser.new
    guest_gvm = AnonGamePresenter.new(
      @game_model,
      @game,
      anon_user,
      @their_play_by_play,
      @is_bot_game
    )
    guest_stream_id = guest_gvm.get_stream_id_for_user(anon_user)
    Turbo::StreamsChannel.broadcast_render_to(
      guest_stream_id,
      partial: "games/update",
      locals: {
        gvm: guest_gvm,
        pre_bot_update_html_string: nil,
        app: AppPresenter.new(anon_user)
      }
    )
  end
end
