class AddPathToFdssNode < ActiveRecord::Migration[7.1]
  def change
    add_column :fdss_nodes, :path, :text
  end
end
