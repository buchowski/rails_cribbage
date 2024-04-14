module Broadcast
  extend ActiveSupport::Concern

  included do
    def broadcast_to_opponent(opponent_gvm, opponent_user)
      opponent_stream_id = opponent_gvm.get_stream_id_for_user(opponent_user)

      Turbo::StreamsChannel.broadcast_render_to(
        opponent_stream_id,
        partial: "games/update",
        locals: {
          gvm: opponent_gvm,
          pre_bot_update_html_string: nil,
          app: AppPresenter.new(opponent_user)
        }
      )
    end

    def broadcast_to_guests(guest_gvm, anon_user)
      # if any guests are watching the game, update their views
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
end
