Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'orders#index'
  get '/orders', to: 'orders#index', :defaults => { :format => 'json' }
end
