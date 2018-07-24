class Room::RankingController < RoomController
  def index
    @ranking_count = 5 # 表示するカウント
  	#該当するセクション（ 実際にはここで日付も意識する)
  	section_ids = Section.where(status: Section::Status::FINISHED, group_id: session[:grp].to_i).pluck(:id)
  	logger.debug(section_ids)

	  #該当するsectionのゲームすべて
	  games = Game.joins(scores: [:player]).select("games.* , scores.*, players.name").where(section_id: section_ids)
#   games.each {|game|
#		logger.debug(sprintf("section_id=%d kind=%d player_id=%d name=%s ,score=%d", game.section_id, game.kind, game.player_id, game.name, game.score))
#	}

	#総得点ランキング(チップを含む)
#  	@rank_totalscores = games.select('games.* , scores.*, players.*, SUM(score) as sum_total').group(:player_id).order('sum_total desc')

  	@rank_totalscores = games.select('SUM(score) as sum_total').group(:player_id).order('sum_total desc').limit(@ranking_count)
#	@rank_totalscores.each { |sum|
#		logger.debug(sprintf("player_id=%d name=%s sum_total=%d",sum.player_id, sum.name, sum.sum_total))
# 	}

	# 対局数、平均スコアの為条件を更新
	  games = games.where.not(kind: 2)
#	games.each {|game|
#		logger.debug(sprintf("name=%s count=%d avg=%d", game.name, game.count_score, game.avg_score))
#	}

	#対局数ランキング
	  @rank_counts = games.select('COUNT(*) as count_score').order('count_score desc').group(:player_id).limit(@ranking_count)
#	@rank_counts.each {|game|
#		logger.debug(sprintf("name=%s count=%d avg=%d", game.name, game.count_score, game.avg_score))
#	}

  	#平均値ランキング
  	@rank_avgs = games.select('AVG(score) as avg_score').order('avg_score desc').group(:player_id).limit(@ranking_count)
#	@rank_avgs.each {|game|
#		logger.debug(sprintf("name=%s count=%d avg=%d", game.name, game.count_score, game.avg_score))
#	}

 	  #MAXスコア(10位まで)
 	  @max_scores = Score.joins(:player).select("scores.*, players.*").where(section_id: section_ids).order(score: :desc).limit(@ranking_count)
#	scores.each{ |score|
#		logger.debug(sprintf("player_id=%d name=%s score=%d",score.player_id, score.name, score.score))
#	}

  end

end
