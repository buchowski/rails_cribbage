Rails.application.routes.draw do
  get 'users/new'
  post 'users', to: "users#create"
  post 'admin-login', to: "users#admin_login"
  post 'login', to: "users#login"
  get 'login', to: "users#index"
  delete 'logout', to: "users#logout"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :games

  # Defines the root path route ("/")
  root "games#index"

  get "/cards", to: "games#cards"
  get "/admin", to: "games#admin"
end
