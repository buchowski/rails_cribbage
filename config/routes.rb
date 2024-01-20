Rails.application.routes.draw do
  devise_for :users
  # TODO update admin-login to use devise
  post 'admin-login', to: "users#admin_login"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :games

  # Defines the root path route ("/")
  root "games#index"

  get "/cards", to: "games#cards"
  get "/admin", to: "games#admin"
end
