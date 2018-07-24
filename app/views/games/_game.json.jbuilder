json.extract! game, :id, :section_id, :game_no, :kind, :created_at, :updated_at
json.url game_url(game, format: :json)
