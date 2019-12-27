namespace :myupdate do
	desc "migration add finished_at "
	task :movefinishedat => :environment do
		sections = Section.all
		puts "before"
		sections.each {|section|
			puts "id:#{section.id} finished_at:#{section.finished_at} updated_at:#{section.uscorepdated_at} "
		}

		sections.where(status: Section::Status::FINISHED, finished_at: nil).update_all('finished_at = updated_at')


		sections = Section.all
		puts "after"
		sections.each {|section|
			puts "id:#{section.id} finished_at:#{section.finished_at} updated_at:#{section.updated_at}"
			if section.finished_at != section.updated_at
				puts "Don't same"
			end
		}

	end


	desc "migration convert kind"
	task :convertkind => :environment do
		puts "precheck starting ..."
		sections = Section.includes(games: [:scores]).all
		error = false
		m4_section_ids = []
		m3_section_ids = []

		sections.each {|section|
#			puts "id:#{section.id} gamekind:#{section.gamekind}"
			kind4m = false
			kind3m = false
			section.games.each {|game|
				if game.kind == 0
					kind4m = true
					if game.scores.length != 4
						puts "section_id:#{section.id} game_id:#{game.id} 四麻のスコア数が４以外です(#{game.scores.length})"
						error = true
					end
				end
				if game.kind == 1
					kind3m = true
					if game.scores.length != 3
						puts "section_id:#{section.id} game_id:#{game.id} 三麻のスコア数が3以外です(#{game.scores.length})"
						error = true
					end
				end
			}
			if kind4m && kind3m
				puts "section_id:#{section.id} 四麻と三麻が混在してます"
				error = true
			end

			if kind4m
				m4_section_ids.push(section.id)
			end

			if kind3m
				m3_section_ids.push(section.id)
			end
		}

		if error
			puts 'precheckでエラーが発生した為更新処理処理を中断します'
		else
			puts 'precheck OK'
			puts '四麻'
			puts m4_section_ids.join(' ')
			puts '三麻'
			puts m3_section_ids.join(' ')
		end

		Rails.logger.debug('cbefor')
		sections.each {|section|
			Rails.logger.debug("section_id:#{section.id} gamekind:#{section.gamekind}")
			section.games.each {|game|
				Rails.logger.debug("   game_id:#{game.id} kind:#{game.kind} scorekind:#{game.scorekind}")
			}
		}

		puts "converting ...."

		ActiveRecord::Base.transaction do
			Section.where(id: m4_section_ids).update_all({gamekind: 0})
			Section.where(id: m3_section_ids).update_all({gamekind: 1})

			Game.where('kind = 0 OR kind = 1').update_all({scorekind: 0})
			Game.where('kind = 2').update_all({scorekind: 1})
		end

		sections = Section.includes(games: [:scores]).all

		Rails.logger.debug('convert')
		sections.each {|section|
			Rails.logger.debug("section_id:#{section.id} gamekind:#{section.gamekind}")
			section.games.each {|game|
				Rails.logger.debug("   game_id:#{game.id} kind:#{game.kind} scorekind:#{game.scorekind}")
			}
		}


	end

	desc "migration add finished_at "
	task :calcgamecount => :environment do
		sections = Section.all
		puts "before"
		sections.each {|section|
			puts "id:#{section.id} games_count:#{section.games_count} games_only_count:#{section.games_only_count} "
		}

		sections = Section.all
		sections.each {|section|
			games_only_count = Game.where(section_id: section.id, scorekind: Game::Scorekind::GAME).count
			games_chip_count = Game.where(section_id: section.id, scorekind: Game::Scorekind::CHIP).count
			puts "s_id:#{section.id} count:#{section.games_count} , g_count:#{games_only_count} , c_count:#{games_chip_count}"
			if section.games_count != games_only_count + games_chip_count
				puts "Error id:#{section.id}"
			end
			Section.where(id: section.id).update({games_only_count: games_only_count})
		}



		sections = Section.all
		puts "after"
		sections.each {|section|
			games_only_count = Game.where(section_id: section.id, scorekind: Game::Scorekind::GAME).count
			puts "s_id:#{section.id} count:#{section.games_count} , g_count:#{section.games_only_count}"
			if section.games_only_count != games_only_count
				puts "verify check error section_id:#{section.id}"
			end
		}

	end


end
