class FdssNode < ApplicationRecord
  def self.DIR_TYPE
    1
  end

  def self.FILE_TYPE
    0
  end

  def self.STAT_SYNCED
    0
  end

  def self.STAT_SYNCING
    1
  end

  def self.STAT_WAIT_SYNC
    2
  end

  def self.root
    FdssNode.find_by(e_id:-1)
  end

  validates :e_id, presence: { message: "e_id 不能为空" }, uniqueness: { message: "e_id 必须是唯一的" }
  validates :node_type, presence: { message: "类型不能为空" }
  validates :name, presence: { message: "名称不能为空" }
  validates :stat, inclusion: { in: [FdssNode.STAT_SYNCED, FdssNode.STAT_SYNCING, FdssNode.STAT_WAIT_SYNC], message: "状态错误" }
  validates :path, presence: { message: "路径不能为空" }, uniqueness: { message: "路径必须是唯一的" }

  def self.create_fdss_node!(fds_json,stat)
    fdss_node = FdssNode.new()
    fdss_node.e_id = fds_json["id"]
    fdss_node.name = fds_json["name"]
    fdss_node.parent_node_id = fds_json["parent_node_id"]
    fdss_node.node_type = fds_json["node_type"]
    fdss_node.md5 = fds_json["md5"]
    fdss_node.path = fds_json["path"]
    fdss_node.stat = stat
    fdss_node.save!
    fdss_node
  end

  def update_path!(parent_node_id, path)
    self.update!(parent_node_id: parent_node_id, path: path)
  end

  def update_name!(name, path)
    self.update!(name:name,path:path)
  end

  def update_stat!(stat)
    self.update!(stat: stat)
  end

end
