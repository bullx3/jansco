class MainController < ApplicationController
  def index
  	redirect_to controller: :personal, action: :index
  	return
  end
end
