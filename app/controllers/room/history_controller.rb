class Room::HistoryController < RoomController

	HISTORIES = [
		{
			date: "2018-09-25",
			title: "更新履歴機能追加",
			body: "更新履歴機能を追加しました。<br>
				   Newアイコンは更新日から三日間表示されます",
			image: nil,
			link: nil
		},
	]

	def index
	end

end
