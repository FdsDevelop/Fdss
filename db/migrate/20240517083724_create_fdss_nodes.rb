class CreateFdssNodes < ActiveRecord::Migration[7.1]
  def change
    create_table :fdss_nodes do |t|
      t.bigint :e_id
      t.bigint :parent_node_id
      t.integer :node_type
      t.string :name
      t.string :md5

      t.timestamps
    end
  end
end
