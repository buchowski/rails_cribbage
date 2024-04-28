Rails.application.routes.draw do
  # disable sign-up, sign-in (devise) for now. focus on quick_game
  if ENV["RAILS_ENV"] == "test"
    resources :games
    root "games#index"
    devise_for :users, module: 'users'
    devise_scope :user do
      post 'admin-login', to: "users/sessions#admin_login"
    end
  else
    root "games#create_quick_game"
  end

  get "/cards", to: "games#cards"
  get "/admin", to: "games#admin"
  get "/quick_game", to: "games#create_quick_game"
  patch "/quick_game", to: "games#update_quick_game"
end
