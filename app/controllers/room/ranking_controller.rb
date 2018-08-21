class Room::RankingController < RoomController
  def index

	# 表示するカウント
    if session[:grp_per] == Player::Permission::ADMIN
		# ルームの管理者は全員の集計が見える
	    @ranking_count = Player.where(group_id: session[:grp], provisional: false).count
    else
	    @ranking_count = 5
	end

	@rankings = Array(2)
	@rankings[0] = {title: "四麻", gamekind: Section::Gamekind::M4}
	@rankings[1] = {title: "三麻", gamekind: Section::Gamekind::M3}

	@rankings.each {|ranking|

		#該当するセクション（ 実際にはここで日付も意識する)
		section_ids = Section.where(status: Section::Status::FINISHED, group_id: session[:grp].to_i, gamekind: ranking[:gamekind]).pluck(:id)
		logger.debug(section_ids)

		  #該当するsectionのゲームすべて
		games = Game.joins(scores: [:player]).select("games.* , scores.*, players.name").where(section_id: section_ids)
		#   games.each {|game|
		#		logger.debug(sprintf("section_id=%d kind=%d player_id=%d name=%s ,score=%d", game.section_id, game.kind, game.player_id, game.name, game.score))
		#	}

		#総得点ランキング(チップを含む)
		ranking[:rank_totalscores] = games.select('SUM(score) as sum_total').group(:player_id).order('sum_total desc').limit(@ranking_count)
		#	@rank_totalscores.each { |sum|
		#		logger.debug(sprintf("player_id=%d name=%s sum_total=%d",sum.player_id, sum.name, sum.sum_total))
		# 	}

		# 対局数、平均スコアの為条件を更新
		no_chip_games = games.where(scorekind: Game::Scorekind::GAME)
		#	games.each {|game|
		#		logger.debug(sprintf("name=%s count=%d avg=%d", game.name, game.count_score, game.avg_score))
		#	}

		ranking[:rank_no_chip_scores] = no_chip_games.select('SUM(score) as sum_total').group(:player_id).order('sum_total desc').limit(@ranking_count)


		#対局数ランキング
		ranking[:rank_counts] = no_chip_games.select('COUNT(*) as count_score').order('count_score desc').group(:player_id).limit(@ranking_count)
		#	@rank_counts.each {|game|
		#		logger.debug(sprintf("name=%s count=%d avg=%d", game.name, game.count_score, game.avg_score))
		#	}

		#平均値ランキング
		ranking[:rank_avgs] = no_chip_games.select('AVG(score) as avg_score').order('avg_score desc').group(:player_id).limit(@ranking_count)
		#	@rank_avgs.each {|game|
		#		logger.debug(sprintf("name=%s count=%d avg=%d", game.name, game.count_score, game.avg_score))
		#	}

		#MAXスコア
		#	@max_scores = Score.joins(:player).select("scores.*, players.*").where(section_id: section_ids).order(score: :desc).limit(@ranking_count)
		ranking[:max_scores] = no_chip_games.order('scores.score desc').limit(@ranking_count)

		#	@max_scores.each{ |game|
		#		logger.debug(sprintf("player_id=%d name=%s score=%d",game.player_id, game.name, game.score))
		#	}

		# 最高スコア(集計あたりの合計)
		ranking[:max_total_scores] = games.select('SUM(score) as sum_score').group(:section_id, :player_id).order('sum_score desc').limit(@ranking_count)
		#	@max_total_scores.each{ |game|
		#		logger.debug(sprintf("player_id=%d name=%s total=%d",game.player_id, game.name, game.sum_score))
		#	}


		chip_games = games.where(scorekind: Game::Scorekind::CHIP)

		#チップ合計
		ranking[:total_chips] = chip_games.select('SUM(score) as sum_chip').group(:player_id).order('sum_chip desc').limit(@ranking_count)

		#	@total_chips.each{ |game|
		#		logger.debug(sprintf("player_id=%d name=%s score=%d",game.player_id, game.name, game.sum_chip))
		#	}



		#チップ最高点(一集計あたり)
		ranking[:max_chips] = chip_games.select('SUM(score) as sum_chip').group(:section_id,:player_id).order('sum_chip desc').limit(@ranking_count)

		#	@max_chips.each{ |game|
		#		logger.debug(sprintf("player_id=%d name=%s score=%d",game.player_id, game.name, game.sum_chip))
		#	}


	}




  end

end
