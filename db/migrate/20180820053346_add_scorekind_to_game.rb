class AddScorekindToGame < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :scorekind, :integer
  end
end
