class ApplicationController < ActionController::Base
  before_action :check_logined

  def check_logined
  	logger.debug('[start] ApplictionController::check_logined')

  	user_id = session[:usr]
    user_per = session[:usr_per]
  	logger.debug('userチェック')
  	logger.debug(user_id)

  	begin
      if user_per.nil? then
        @usr = nil
        raise RuntimeError
      end

  		@usr = User.find(user_id)
  	rescue ActiveRecord::RecordNotFound
		  logger.debug('登録なし')
  		reset_session
    rescue RuntimeError
      logger.debug('Not permission')
      reset_session
  	end
	

  	unless @usr
  		# user情報を取得できなった場合はログイン画面に遷移
	  	logger.debug('ログイン画面に遷移')
  		flash[:reffer] = request.fullpath
  		redirect_to login_path
  	end

  	logger.debug('[finished] ApplictionController::check_logined')
  end


end
