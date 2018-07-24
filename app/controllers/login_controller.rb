class LoginController < ApplicationController

	skip_before_action :check_logined

	def index
		

	end

	def auth

		username = params[:username]
		password = params[:password]


#		usr = User.find_by(username: username)
		usr = User.authenticate(username, password)

#		if usr != nil && usr.password = password
		if usr then
			logger.debug('ログイン成功')
			reset_session
			session[:usr] = usr.id
			redirect_to params[:reffer]
		else
			flash.now[:reffer] = params[:reffer]
			@error = 'ユーザー名またはパスワードが間違っています'
			render 'index'
		end
	end

	def logout
		reset_session
		redirect_to ''
		
	end


end
