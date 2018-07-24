class ApplicationController < ActionController::Base
  before_action :check_logined

  def check_logined
  	logger.debug('[start] ApplictionController::check_logined')

  	user_id = session[:usr]
  	logger.debug('userチェック')
  	logger.debug(user_id)

  	begin
  		@usr = User.find(user_id)
  	rescue ActiveRecord::RecordNotFound
		  logger.debug('登録なし')
  		reset_session
  	end
	

  	unless @usr
  		# user情報を取得できなった場合はログイン画面に遷移
	  	logger.debug('ログイン画面に遷移')
  		flash[:reffer] = request.fullpath
  		redirect_to controller: :login, action: :index
  	end

  	logger.debug('[finished] ApplictionController::check_logined')
  end


end
