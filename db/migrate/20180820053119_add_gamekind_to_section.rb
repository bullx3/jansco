class AddGamekindToSection < ActiveRecord::Migration[5.2]
  def change
    add_column :sections, :gamekind, :integer
  end
end
