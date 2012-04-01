SimpleGallery::Application.routes.draw do

  match 'user/edit' => 'users#edit', :as => :edit_current_user

  match 'signup' => 'users#new', :as => :signup

  match 'logout' => 'sessions#destroy', :as => :logout

  match 'login' => 'sessions#new', :as => :login

  resources :sessions

  resources :users

  get "photos/:hash.jpg", to: "photos#shared", as: "photo_share"
  resources :photos

  root to: "photos#index"
end
