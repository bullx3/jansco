class RemoveKindFromGame < ActiveRecord::Migration[5.2]
  def change
    remove_column :games, :kind, :integer
  end
end
