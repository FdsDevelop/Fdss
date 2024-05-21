class AddStatToFdssNode < ActiveRecord::Migration[7.1]
  def change
    add_column :fdss_nodes, :stat, :integer
  end
end
