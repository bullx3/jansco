class MainController < ApplicationController
  def index
  	user_id = session[:usr]
  	@user = User.find(user_id)
  end
end
