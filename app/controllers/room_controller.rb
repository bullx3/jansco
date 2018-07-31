class RoomController < ApplicationController
  before_action :check_group, except: [:notice]

  def show
  	logger.debug('[START] RoomController::index')
  	@g_idname = params[:g_idname]
  	@group = Group.find_by(idname: @g_idname)

    # 対局中セクションの取得
    sections = Section.where(status: Section::Status::PLAYING, group_id: @group.id)
    @now_count = sections.size

    if @now_count > 0
      max_sections = sections.select(:section_players_count).order(section_players_count: :desc).limit(1)

      @player_cnt = max_sections[0].section_players_count

      #SectonPlayersの並び順はそのままにすべて取得
      @playing_sections = sections.includes(section_players: [:player])
    end

    # 未清算のセクションの取得
    sections = Section.where(status: Section::Status::FINISHED,  group_id: @group.id, all_paid: false)
    @no_paic_count = sections.size
    if @no_paic_count > 0
      max_sections = sections.select(:section_players_count).order(section_players_count: :desc).limit(1)
      @no_paid_player_cnt = max_sections[0].section_players_count
      @no_paid_sections = sections.includes(section_players: [:player])
    end

    # 終了したセクションの取得
    sections = Section.where(status: Section::Status::FINISHED,  group_id: @group.id).limit(3)
    @past_count = sections.size
    if @past_count > 0
      max_sections = sections.select(:section_players_count).order(section_players_count: :desc).limit(1)

      @past_player_cnt = max_sections[0].section_players_count
      @past_sections = sections.includes(section_players: [:player])
    end

  	logger.debug('[FINISH] RoomController::index')
  end

  def notice
  	@notice = params[:notice]
  	@alert = params[:alert]
  end

private
  # 現在のユーザーが指定したグループに属しているか？
  # 使うタイミングはユーザーのログインチェックは完了している為session[:usr]が見つからないことはない
  # group チェックするグループのモデルオブジェクト
  def check_usr(group)

  	@group.users.each {|user|
  		if user.id == session[:usr]
		  	logger.debug('グループとユーザーが一致')
  			return true
  		end
  	}
  	logger.debug('グループとユーザーが一致しない')
  	return false
  end

  def check_group
  	logger.debug('[START] RoomController::check_group')

  	grp_id = session[:grp]
  	logger.debug(grp_id)
  	grp_path = params[:g_idname]
    logger.debug(grp_path)


  	begin
  		if grp_id
	  		@group = Group.find(grp_id)
	  		if @group.idname != grp_path
			    logger.debug('session[:grp]のidnameとパスが一致しない')
			    @group = nil
		  		@group = Group.find_by!(idname: grp_path)
		  	end
	  	else
	  		# 初回アクセス時など、find_by!は見つからない時例外を発生する
		    logger.debug('session[:grp]が存在しない')
	  		@group = Group.find_by!(idname: grp_path)
	  	end
  	rescue ActiveRecord::RecordNotFound
	    logger.debug('Group登録なし')
  	end

  	if @group && check_usr(@group)
  		# 今のユーザーが認められている
	    logger.debug('ユーザー権あり	')
      # ここに来た時点でGroupとUserが一致するプレイヤーは存在する為エラーにはならないはず
      player = Player.find_by(user_id: session[:usr], group_id: @group.id)

		  session[:grp] = @group.id
      session[:grp_per] = player.permission
      @main_title = @group.name
  	else
  		session[:grp] = nil
  		# 現在のページは表示できませんに戻ってメインの画面（ユーザートップに戻る）
  		redirect_to controller: :room, action: :notice, alert: '存在しないルームか、	許可されていないルームです'
    end

  	logger.debug('[FINISH] RoomController::check_group')
  end

end
