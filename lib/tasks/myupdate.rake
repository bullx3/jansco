namespace :myupdate do
	desc "migration add finished_at "
	task :movefinishedat => :environment do
		sections = Section.all
		puts "before"
		sections.each {|section|
			puts "id:#{section.id} finished_at:#{section.finished_at} updated_at:#{section.updated_at} "
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
end
