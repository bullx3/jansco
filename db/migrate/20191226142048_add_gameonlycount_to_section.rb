class AddGameonlycountToSection < ActiveRecord::Migration[5.2]
  def change
    add_column :sections, :games_only_count, :integer, default: 0
  end
end
