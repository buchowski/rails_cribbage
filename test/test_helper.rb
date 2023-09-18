ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def sign_in_as(user_id)
    post admin_login_url, params: { user_id: user_id }
  end

  def sign_in_as_cindy()
    sign_in_as(User.find_by_name('Cindy').id)
  end

  def sign_in_as_barbara()
    sign_in_as(User.find_by_name('Barbara').id)
  end

  def start_bot_game_as(user_name)
    user = User.find_by_name(user_name)
    sign_in_as(user.id)
    bot = User.where(is_bot: true).first

    post games_path, params: { bot_id: bot.id }

    return [user, bot]
  end

  def get_playable_cards(hand)
    hand.filter { |card_id, is_playable| is_playable }
  end
end
