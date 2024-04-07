Rails.application.routes.draw do
  devise_for :users, module: 'users'
  devise_scope :user do
    post 'admin-login', to: "users/sessions#admin_login"
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :games

  # Defines the root path route ("/")
  root "games#index"

  get "/cards", to: "games#cards"
  get "/admin", to: "games#admin"
  get "/quick_game", to: "games#create_quick_game"
  patch "/quick_game", to: "games#update_quick_game"
end
