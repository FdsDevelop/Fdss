require 'net/http'
class FileSyncJob < ApplicationJob
  queue_as :default

  @@job_running = false

  def perform(*args)
    # Do something later
    unless @@job_running
      @@job_running = true
        begin
          fds_root_id = get_fds_root_id
          ids = get_ids
          ids_infos = get_ids_infos(ids)
          e_ids = get_eids
          mysn,mnsy,mysy = classify_ids(ids,e_ids)

          puts ""
          puts "========================================================================================"
          puts ""
          puts "fds root id = #{fds_root_id}"
          puts "ids = #{ids}"
          puts "e_ids = #{e_ids}"
          puts ""
          # puts "-------------------------------------------------"
          # puts ""
          # puts "ids_infos = #{ids_infos}"
          # puts ""
          puts "========================================================================================"
          puts ""



          if mnsy.present?
            puts "mnsy = #{mnsy}"
            mnsy_deal(mnsy,ids_infos,fds_root_id)
          end

          if mysn.present?
            puts "mysn = #{mysn}"
            mysn_deal(mysn,ids_infos,fds_root_id)
          end

          if mysy.present?
            puts "mysy = #{mysy}"
            mysy_deal(mysy,ids_infos,fds_root_id)
          end

        rescue => e
          puts "error message #{e.message}"
        end
      @@job_running = false
    else
      puts "job is running..."
    end
  end

  def mnsy_deal(mnsy,ids_infos,fds_root_id)
  #   分布端存在，主端不存在的，直接删除即可
    root_path = Rails.application.config.fdss.storage_path
    mnsy.each do |e_id|
      fdss_node = FdssNode.find_by!(e_id: e_id.to_i)
      path = fdss_node.path
      fdss_node.update_stat!(FdssNode.STAT_SYNCING)
      file_path = File.join(root_path,path)
      FileUtils.rm_rf(file_path) if File.exist?(file_path)
      fdss_node.destroy!
    end
  end

  def mysn_deal(mysn,ids_infos,fds_root_id)
  #   主端存在，分布端不存在的，要创建
    mysn.each do |e_id|
      create_fdss(ids_infos, e_id.to_s, fds_root_id)
    end
  end

  def create_fdss(infos,e_id,fds_root_id)
    # puts "now start create #{infos[e_id]}"
    sleep(1)
    fdss_node = FdssNode.find_by(e_id: e_id.to_i)
    unless fdss_node
      parent_id = infos[e_id]["parent_node_id"].to_i
      parent_fdss_node = FdssNode.find_by(e_id: parent_id)
      unless parent_fdss_node
        if parent_id == fds_root_id
          create_fdss_node(infos[e_id])
        else
          # puts "create parent node #{infos[e_id]["parent_node_id"]},frist"
          create_fdss(infos,parent_id.to_s, fds_root_id)
          create_fdss(infos,e_id,fds_root_id)
        end
      else
        create_fdss_node(infos[e_id])
      end
    # else
    #   puts "#{infos[e_id]} already create"
    end
  end

  def create_fdss_node(info)
    puts "create #{info}"
    root_path = Rails.application.config.fdss.storage_path

    node_path = File.join(root_path,info["path"])
    if info["node_type"] == FdssNode.DIR_TYPE
      FileUtils.mkdir_p(node_path)
    elsif info["node_type"] == FdssNode.FILE_TYPE
      download_file(info["id"],node_path, info["md5"])
    else
      raise "FdssNode type error"
    end
    FdssNode.create_fdss_node!(info,FdssNode.STAT_SYNCED)
  end

  def download_file(e_id,destination,md5)
    uri = URI.parse("#{Rails.application.config.fds.wan_address}/fdss_download?id=#{e_id}")
    Net::HTTP.start(uri.host,uri.port) do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request) do |response|
        if response.code.to_i >= 200 && response.code.to_i < 300
          open(destination,'wb') do |file|
            response.read_body do |chunk|
              file.write(chunk)
            end
          end
        else
          raise "download error, http status #{response.code}"
        end
      end
    end
    new_file_md5 = Digest::MD5.hexdigest(File.read(destination))
    if new_file_md5.to_s.upcase != md5.to_s.upcase
      raise "download failed, file check failed"
    end
  end

  def mysy_deal(mysy,ids_infos, fds_root_id)
    root_path = Rails.application.config.fdss.storage_path
    mysy.each do |e_id|
      fdss_node = FdssNode.find_by(e_id: e_id)
      fdss_node.update_stat!(FdssNode.STAT_SYNCING)
      fds_info = ids_infos[e_id.to_s]
      if fdss_node.parent_node_id != fds_info["parent_node_id"] || fdss_node.name != fds_info["name"]
        old_path = File.join(root_path,fdss_node.path)
        new_path = File.join(root_path,fds_info["path"])
        puts "move #{old_path} to #{new_path}"
        fdss_node.update_path!(fds_info["parent_node_id"],new_path)
        FileUtils.mv(old_path,new_path)
      end
      if fdss_node.md5 != fds_info["md5"] # 这种情况不会出现，如果出现就把文件删除，等下次同步时再下载
        old_path = File.join(root_path,fdss_node.path)
        FileUtils.rm(old_path)
        fdss_node.destroy
        puts "wtf!!! md5 changed!"
      end
      fdss_node.update_stat!(FdssNode.STAT_SYNCED)
    end

  end

  def classify_ids(ids,e_ids)
    mysn = ids - e_ids
    mnsy = e_ids - ids
    mysy = ids & e_ids
    [mysn,mnsy,mysy]
  end

  def get_ids_infos(ids)
    ids_infos = {}
    ids_groups = ids.each_slice(25).to_a
    ids_groups.each do |ids_group|
      ids_infos = ids_infos.merge(get_infos(ids_group))
    end
    ids_infos
  end

  def get_eids
    node_ids = FdssNode.all.pluck(:e_id)
  end

  def get_fds_root_id
    url = URI.parse("#{Rails.application.config.fds.wan_address}/get_root_info")
    http = Net::HTTP.new(url.host, url.port)
    http.read_timeout = 30
    request = Net::HTTP::Post.new(url.path)
    request_body = {}
    request.set_form_data({data: request_body.to_json})
    response = http.request(request)
    ret =JSON.parse(response.body)
    if ret["ret_code"] != 0
      raise ret["err_msg"]
    end
    ret["data"]["root"]["id"].to_i
  end

  def get_ids
    url = URI.parse("#{Rails.application.config.fds.wan_address}/get_all_node_ids")
    http = Net::HTTP.new(url.host, url.port)
    http.read_timeout = 30
    request = Net::HTTP::Post.new(url.path)
    request_body = {}
    request.set_form_data({data: request_body.to_json})
    response = http.request(request)
    ret =JSON.parse(response.body)
    if ret["ret_code"] != 0
      raise ret["err_msg"]
    end
    ret["data"]["all_node_ids"]
  end

  def get_infos(ids)

    url = URI.parse("#{Rails.application.config.fds.wan_address}/get_nodes_info")
    http = Net::HTTP.new(url.host, url.port)
    http.read_timeout = 30
    request = Net::HTTP::Post.new(url.path)
    request_body = {}
    request_body[:node_ids] = ids
    request.set_form_data({data: request_body.to_json})
    response = http.request(request)
    ret = JSON.parse(response.body)
    if ret["ret_code"] != 0
      raise ret["err_msg"]
    end
    ret["data"]["nodes"]
  end

end
