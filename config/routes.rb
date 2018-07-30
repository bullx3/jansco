Rails.application.routes.draw do
  resources :logs
  resources :comments
  resources :groups
  resources :users
  resources :players
  resources :scores
  resources :games
  resources :section_players
  resources :sections

  get 'login/index'
  post 'login/auth'
  get 'login/confirmLogout'
  get 'login/logout'
  get 'login/denied'

  get 'admin' => 'admin#index', as: :admin
  get 'admin/index'
  get 'admin/notice'
  get 'admin/newUser'
  post 'admin/createUser'
  get 'admin/editUser'
  post 'admin/updateUser'

  get 'admin/newGroup'
  post 'admin/createGroup'
  get 'admin/newPlayer'
  post 'admin/createPlayer'

  get 'r/:g_idname' => 'room#show' , as: :room
  get 'r/:g_idname/notice' => 'room#notice'
  get 'r/:g_idname/config/' => 'room/config#index', as: :config_room
  get 'r/:g_idname/config/notice' => 'room/config#notice'
  get 'r/:g_idname/config/newPlayer' => 'room/config#newPlayer'
  post 'r/:g_idname/config/createPlayer' => 'room/config#createPlayer'

  get 'r/:g_idname/playing/new' => 'room/playing#new', as: :new_room_playing
  post 'r/:g_idname/playing/create' => 'room/playing#create', as: :create_room_playing
  get 'r/:g_idname/playing/:id' => 'room/playing#show', as: :room_playing
  post 'r/:g_idname/playing/:id/edit' => 'room/playing#edit', as: :edit_room_playing
  post 'r/:g_idname/playing/:id/add' => 'room/playing#add', as: :add_room_playing
  post 'r/:g_idname/playing/:id/update' => 'room/playing#update', as: :update_room_playing
  post 'r/:g_idname/playing/:id/delete' => 'room/playing#delete', as: :delete_room_playing
  post 'r/:g_idname/playing/:id/editPlayer' => 'room/playing#editPlayer'
  post 'r/:g_idname/playing/:id/changePlayer' => 'room/playing#changePlayer', as: :change_room_playing
  get 'r/:g_idname/playing/:id/finish' => 'room/playing#finish', as: :finish_room_playing
  get 'r/:g_idname/playing/:id/restart' => 'room/playing#restart', as: :restart_room_playing
  post 'r/:g_idname/playing/:id/pay' => 'room/playing#pay'
  get 'r/:g_idname/playing/:id/pay_all' => 'room/playing#pay_all'

  get 'r/:g_idname/ranking' => 'room/ranking#index', as: :room_ranking



  get 'r/:g_idname/playing/:id/notice' => 'room/playing#notice', as: :notice_room_playing
  get 'r/:g_idname/playing/:id/destroy' => 'room/playing#destroy', as: :destroy_room_playing


  get 'main/index'
  root to: 'main#index', as: :top
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
