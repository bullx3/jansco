class CreateGames < ActiveRecord::Migration[5.2]
  def change
    create_table :games do |t|
      t.integer :section_id
      t.integer :game_no
      t.integer :kind

      t.timestamps
    end
  end
end
