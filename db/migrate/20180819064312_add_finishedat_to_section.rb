class AddFinishedatToSection < ActiveRecord::Migration[5.2]
  def change
    add_column :sections, :finished_at, :datetime
  end
end
