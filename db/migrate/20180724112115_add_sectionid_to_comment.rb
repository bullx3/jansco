class AddSectionidToComment < ActiveRecord::Migration[5.2]
  def change
    add_column :comments, :section_id, :integer
  end
end
