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
end
