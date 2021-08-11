Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get 'home/index'
  post 'home/create_receive_address', action: :create_receive_address, controller: 'home'

  devise_for :users
  root to: 'home#index'
end
