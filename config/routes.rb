Rails.application.routes.draw do
  get 'users/new'
  post 'users', to: "users#create"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :games

  # Defines the root path route ("/")
  root "games#index"

  get "/cards", to: "games#cards"
  get "/admin", to: "games#admin"
end
