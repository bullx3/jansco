class Room::PlayingController < RoomController
  RateStrings = [{name: "点５",  rate: 50 , checked: false},
 	      		     {name: "点ピン", rate: 100, checked: false},
  		        	 {name: "手動", rate: 0  , checked: false}]
  GameKindString = {"0" => "四麻", "1" => "三麻", "2" =>"ﾁｯﾌﾟ"}


  def new
  	@players_all = Player.where(group_id: session[:grp], provisional: false)

  	@rateStrings = RateStrings

  end

  def create

    playersArray = params[:players]

    if playersArray.length == 0
      redirect_to action: :notice, alert: 'プレイヤーが選択されていません'
      return
    end

    # セクションを追加
    section = Section.new
    section.status = Section::Status::PLAYING
    section.group_id = session[:grp].to_i
    section.all_paid = false

    if params[:rate] != nil
      rate = params[:rate].to_i
      section.rate = (rate == 0) ? params[:inputRate].to_i : rate
    end

    #トランザクション開始
    ActiveRecord::Base.transaction do

      section.save!

      @section_id = section.id
      playersArray.each { |playerId|
        s_player = SectionPlayer.new
        s_player.section_id = @section_id
        s_player.player_id = playerId
        s_player.total = nil # 作ったばかりなので値はnil
        s_player.paid = false
        s_player.save!
      }

      text = sprintf('create rate:%s p_id[%s]', params[:rate], playersArray.join(','))
      log = Log.newLog(@section_id, session[:usr], text)
      log.save!
    end # トランザクション終了



    # save後ならsection.idがとれる
    url = room_playing_path(params[:g_idname], @section_id.to_s)

    redirect_to url

  end # create

  def show
  	@section_id = params[:id].to_i
    @show_active = true  # false: 終了済み true:実行中

  	if !(Section.exists?(id: @section_id))
		  redirect_to action: :notice, alert: 'そのゲームはありません'
  	  return
  	end

  	stm = ScoreTableManager.new(@section_id)
    @scoreTable = stm.getScoreTable
    @sectionPlayers = stm.getSectionPlayersWithPlayerName

    @section = stm.getSection

    @gameKindString = GameKindString

    @comments = Comment.where(section_id: @section_id)

    @show_restart = false
    @show_destroy = false
    if session[:grp_per] == Player::Permission::ADMIN
      # ルームの権限が管理者の時のみ終了応対からもどせる。またsection削除も可能
      @show_restart = true
      @show_destroy = true
    end



  	# 既に終了している場合は終了済みのスコアビューを表示
  	section = Section.find(@section_id)
  	if section.status == Section::Status::FINISHED
      @show_active = false
  		render 'showFinished'
  		return
  	end

  end # show

  def edit
    section_id = params[:id]
    @gameKindString = GameKindString
    @mode = params[:mode]
    @gameHash = {}


    stm = ScoreTableManager.new(section_id)
    if @mode == 'add'
      sectionPlayers = stm.getSectionPlayersWithPlayerName

      @gameHash[:id] = nil
      @gameHash[:gameNo] = -1
      @gameHash[:kind] = nil
      @gameHash[:scores] = Array.new
      sectionPlayers.each {|sPlayer|
        scoreHash = {p_id: sPlayer.player_id,
                     p_name: sPlayer.player.name,
                     score: ''}
        @gameHash[:scores].push(scoreHash)
      }
      logger.debug(@gameHash)

      @subtitle = 'スコア追加'

    elsif @mode == 'update'
      @gameNo = params[:gameNo].to_i
      scoreTable = stm.getScoreTable
      scoreTable.each {|score|
        if score[:gameNo] == @gameNo
          @gameHash = score
          break
        end
      }
      logger.debug(@gameHash)
      @subtitle = 'スコア編集'


    else
      raise 'edit mode argument error'
    end

    @player_ids = stm.getPlayerIds

  end

  def add

    section_id = params[:id]
    kind = params[:kind].to_i

    # game_noを決める為game_noの大きい順で取り出し
    games = Game.where(section_id: section_id).order(game_no: :desc).limit(1)

    if (games.length > 0)
      # 最後のgame_noにインクリメントする
      logger.debug('last game_no=' + games[0].game_no.to_s)
      game_no = games[0].game_no + 1
    else
      #新規追加
      game_no = 0
    end

    #トランザクション開始
    ActiveRecord::Base.transaction do

      game = Game.new
      game.section_id = section_id
      game.game_no = game_no
      game.kind = kind
      game.save!

      game_id = game.id  # Gameテーブルに追加した後しかidを取得できない

      # scoreテーブルの書き込み
      params[:input].each {|p_id, s|
        if(s != "")
          score = Score.new
          score.game_id = game_id
          score.player_id = p_id.to_i
          score.score = s.to_i
          score.section_id = section_id
          score.save!
        end
      }

      # この処理はscore書き込み後でないとだめ
      stm = ScoreTableManager.new(section_id)
      stm.updateTotalScores  #この処理内でupdate済み

      text = sprintf('add game:%d kind:%d score:%s', game_no, kind, params[:input].to_json)
      log = Log.newLog(section_id, session[:usr], text)
      log.save!

    end # transaction end

    redirect_to action: :show

  end #add

  def update
    section_id = params[:id].to_i
    updateGameNo = params[:gameNo].to_i
    selectKind = params[:kind].to_i

    #トランザクション開始
    ActiveRecord::Base.transaction do

      #Gameテーブルは変更がある時だけ
      games = Game.where('section_id = ? AND game_no = ?',section_id, updateGameNo)
      updateGame = games[0]   #一つしかとれない前提

      logger.debug('game_id=' + updateGame.id.to_s)

      if updateGame.kind != selectKind
        updateParams = {kind: selectKind}
        updateGame.update(updateParams)
      end

      #現在scoreテーブルの内容は削除して新たに追加
      Score.where('game_id = ?', updateGame.id.to_s).delete_all

      params[:input].each {|p_id, s|

        if(s != "")
          score = Score.new
          score.game_id = updateGame.id
          score.player_id = p_id.to_i
          score.score = s.to_i
          score.section_id = section_id
          score.save!
        end
      }
      # 合計値の更新
      # この処理はscore書き込み後でないとだめ
      stm = ScoreTableManager.new(section_id)
      stm.updateTotalScores  #この処理内でupdate済み

      text = sprintf('update game:%d kind:%d score:%s', updateGameNo, selectKind, params[:input].to_json)
      log = Log.newLog(section_id, session[:usr], text)
      log.save!

    end  # トランザクション終了

    redirect_to action: :show

  end #update

  def delete
    section_id = params[:id].to_i
    deleteGameNo = params[:gameNo].to_i

    #トランザクション開始
    ActiveRecord::Base.transaction do

      # ここでは関連づけたScoreテーブルの要素を削除する為にdestroy_allを使用する。
      # アソシエーションの関連づけに"dependent: :destroy"追加済み
      Game.where('section_id = ? AND game_no = ?',section_id, deleteGameNo).destroy_all

      # この処理はscore書き込み後でないとだめ
      stm = ScoreTableManager.new(section_id)
      stm.updateTotalScores  #この処理内でupdate済み

      text = sprintf('delete game:%d', deleteGameNo)
      log = Log.newLog(section_id, session[:usr], text)
      log.save!

    end

    redirect_to action: :show

  end #delete

  def editPlayer
    section_id = params[:id].to_i

    @players_all = Player.where(group_id: session[:grp], provisional: false)
    @rateStrings = RateStrings.deep_dup

    stm = ScoreTableManager.new(section_id)
    @player_ids = stm.getPlayerIds
    @total_scores = stm.getTotalScores

    rate = stm.getSection.rate

    @custom_rate = nil

    unless rate.nil?
      flg = false
      @rateStrings.each {|rate_s|
        if rate_s[:rate] == rate
          logger.debug('rate:' + rate.to_s)
          rate_s[:checked] = true
          flg = true
        elsif !flg && rate_s[:rate] == 0
          logger.debug('その他のrate:' + rate.to_s)
          rate_s[:checked] = true
          @custom_rate = rate
        end
      }
    end
    logger.debug(@rateStrings)

  end

  def changePlayer
    section_id = params[:id].to_i
    playersArray = params[:players].map {|id| id.to_i}

    if params[:rate] != nil
      set_rate = params[:rate].to_i
      set_rate = (set_rate == 0) ? params[:inputRate] : set_rate
    else
      set_rate = nil
    end


    logger.debug('select players:')
    logger.debug(playersArray)


    stm = ScoreTableManager.new(section_id)
    player_ids = stm.getPlayerIds
    rate = stm.getSection.rate

    # 追加分
    add_list = playersArray - player_ids
    logger.debug('add_list:')
    logger.debug(add_list)

    # 削除分
    del_list = player_ids - playersArray
    logger.debug('del_list:')
    logger.debug(del_list)


    if (add_list.length == 0 ) && (del_list.length == 0) && (rate == set_rate)
      #追加も削除もない場合はエラー表示
      redirect_to action: :notice, alert: 'メンバーまたはレートが変更されていいません'
      return
    end

    # 既にスコア登録されているプレイヤーは削除できないのでエラー（クライアント側でチェックできなくしているのでこないはず）
    total_scores = stm.getTotalScores
    del_list.each{|del_player_id|
      position = player_ids.index(del_player_id)
      t_score = total_scores[position]
      if !(t_score.nil?)  
        redirect_to action: :notice, alert: '既にスコア登録のあるプレイヤーは削除できません'
        return
      end
    }


    ActiveRecord::Base.transaction do

      add_list.each {|add_Pid|
        s_player = SectionPlayer.new
        s_player.section_id = section_id
        s_player.player_id = add_Pid
        s_player.total = nil
        s_player.save!
      }

      del_list.each {|del_Pid|
        SectionPlayer.where('section_id = ? AND player_id = ?',section_id, del_Pid).destroy_all
      }

#      stm = ScoreTableManager.new(section_id)
      section = Section.find(section_id)
      section.update({rate: set_rate})

      text = sprintf('changePlayer rate:%s add[%s] delete[%s]', set_rate, add_list.join(':'), del_list.join(':'))
      log = Log.newLog(section_id, session[:usr], text)
      log.save!

    end # トランザクション終了


    redirect_to action: :show

  end #changePlayer

  def finish
    section_id = params[:id]
    section = Section.find(section_id)

    if section.status != Section::Status::PLAYING
      #現在対局中でなければエラー
      raise 'already finished'
    end

    if(section.games_count == 0)
      #対応するゲームを入力していない場合はsectionごと消す
      redirect_to action: :destroy
      return
    end



    ActiveRecord::Base.transaction do
      # 状態を終了状態に変更
      section.update!({status: Section::Status::FINISHED})
      # totalスコアがnil(つまり名前だけ作ってスコアを入れていない場合はプレイヤーリストから消す)
      SectionPlayer.where('section_id = ? AND total is ?', section_id, nil).destroy_all

      text = sprintf('finish')
      log = Log.newLog(section_id, session[:usr], text)
      log.save!

    end # トランザクション終了


    redirect_to action: :show

  end #finidh

  def restart
    section_id = params[:id]
    section = Section.find(section_id)

    if section.status != Section::Status::FINISHED
      #現在終了中でなければエラー
      raise 'already finished'
    end

    ActiveRecord::Base.transaction do
      # 状態を対局中状態に変更
      section.update!({status: Section::Status::PLAYING})

      text = sprintf('restart')
      log = Log.newLog(section_id, session[:usr], text)
      log.save!
    end # トランザクション終了

    redirect_to action: :show

  end

  def destroy
    section_id = params[:id]
    section = Section.find(section_id)

    ActiveRecord::Base.transaction do
      text = sprintf('destroy')
      log = Log.newLog(section_id, session[:usr], text)
      log.save!

      # ここでは関連づけたGames、Scoreテーブルの要素を削除する為にdestroy_allを使用する。
      # アソシエーションの関連づけに"dependent: :destroy"追加済み
      section.destroy

    end # トランザクション終了

    redirect_to room_path(params[:g_idname])

  end #destroy

  def pay 
    section_id = params[:id].to_i
    player_id = params[:player_id].to_i

    sectionPlayer = SectionPlayer.find_by(section_id: section_id, player_id: player_id)

    paid = !(sectionPlayer.paid)


    ActiveRecord::Base.transaction do

      sectionPlayer.update({paid: paid})

      no_paid_count = SectionPlayer.where(section_id: section_id, paid: false).count

      section = Section.find(section_id)

      if no_paid_count == 0 && section.all_paid == false
        section.update({all_paid: true})
      elsif no_paid_count > 0 && section.all_paid == true
        section.update({all_paid: false})
      end

      text = sprintf('pay p_id:%d set:%s', player_id, paid)
      log = Log.newLog(section_id, session[:usr], text)
      log.save!

    end # トランザクション終了

    redirect_to action: :show

  end

  def pay_all
    section_id = params[:id].to_i

    ActiveRecord::Base.transaction do

      SectionPlayer.where(section_id: section_id).update({paid: true})
      Section.find(section_id).update({all_paid: true})

      text = sprintf('pay_all')
      log = Log.newLog(section_id, session[:usr], text)
      log.save!

    end # トランザクション終了

    redirect_to action: :show

  end

  def notice
    @notice = params[:notice]
    @alert = params[:alert]
  end #notice

private

  class ScoreTableManager

    def initialize(section_id)
      @section_id = section_id
      @player_ids = Array.new  #例 [1,5,9,4,10]
      @total_scores = Array.new #例 [50,10.-30,-20,-10]
      @total_players = Array.new

      @table_scores = Array.new
      @rate = nil

      @section = Section.find(section_id)



      @splayers = SectionPlayer.includes(:player).where(section_id: section_id)

      #TODO section作成時に同時に作るので取れないことはないはずだが、万が一とれなかったらscoreテーブルから再構築？

      @splayers.each { |player|
        @player_ids.push(player.player_id)
        @total_scores.push(player.total)
        total_player = {id: player.player_id,
                        total: player.total,
                        paid: player.paid,
                        name: player.player.name}
        @total_players.push(total_player)
      }


    if (@section.games.size == 0)
      # まだスコアを登録していない。または削除により値がなくなった

      @total_scores.fill(0)
    end

    games = Game.includes(scores: [:player]).where(section_id: section_id)

    games.each{|game|
      gameHash = {}
      gameHash[:id] = game.id
      gameHash[:gameNo] = game.game_no
      gameHash[:kind] = game.kind
      gameHash[:scores] = Array.new
      @splayers.each {|sPlayer|
        scores_score = nil
        game.scores.each {|score|
          if sPlayer.player_id == score.player_id
            # sectionPlayersのプレイヤーIDとscoresのプレイヤーIDが一致
            # scores.player_id の方にないことはあるのでこを通らない。その場合はnil
            scores_score = score.score
            break
          end
        }
        scoreHash = {p_id: sPlayer.player_id,
                     p_name: sPlayer.player.name,
                     score: scores_score}
        gameHash[:scores].push(scoreHash)
      }
      Rails.logger.debug(gameHash)
      @table_scores.push(gameHash)
    }
    # update/delete後の合計値変更もあるので再計算
    sumScores = Score.where(section_id: section_id).select('player_id, SUM(score) as sum_score').group(:player_id)

    @total_scores = Array.new(@player_ids.length)

    sumScores.each{|sumScore|
      postion = @player_ids.index(sumScore.player_id)
      @total_scores[postion] = sumScore.sum_score
    }


    Rails.logger.debug(@player_ids)
    Rails.logger.debug(@total_scores)

    end # initialize end


    def getScoreTable
      return @table_scores
    end

    def getTotalScores
      return @total_scores
    end

    def getPlayerIds
        return @player_ids
    end

    def getSectionPlayersWithPlayerName
        return @splayers
    end


    # 現在のscoreテーブルの状況に合わせsection_Playersの更新を行う
    def updateTotalScores

      @player_ids.length.times do |cnt|
        s_playrs = SectionPlayer.where('section_id = ? AND player_id = ?',@section_id, @player_ids[cnt]).limit(1)
        s_playrs[0].update({total: @total_scores[cnt]})
      end
    end

    def updatVerify
      # 不整合をチェックしてＤＢを更新する

    end

    def getSection
      return @section
    end



  end # class end 


end
