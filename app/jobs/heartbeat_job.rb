class HeartbeatJob < ApplicationJob

  @@heartbeat_job_running = false

  queue_as :default

  def perform(*args)
    unless @@heartbeat_job_running
      @@heartbeat_job_running = true
      # Do something later
      for i in 1..60 do
        puts "xiaohu heartbeat"
        sleep 1
      end
      @@heartbeat_job_running = false
    else
      puts "heartbeat job is running"
    end
  end
end
