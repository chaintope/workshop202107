Rails.application.routes.draw do

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get 'home/index'
  post 'home/create_receive_address', action: :create_receive_address, controller: :home
  post 'home/generate', action: :generate, controller: 'home'
  post 'home/payment', action: :payment, controller: 'home'

  get 'timestamp/index', controller: :timestamp, action: :index
  post 'timestamp/register', controller: :timestamp, action: :register
  post 'timestamp/verify', controller: :timestamp, action: :verify

  get 'token/index'
  post 'token/issue'
  post 'token/send_token'

  devise_for :users
  root to: 'home#index'
end
