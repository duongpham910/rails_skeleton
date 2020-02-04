worker_processes 4
timeout 180

listen "/var/www/rails-skeleton/shared/tmp/unicorn.sock"
pid "/var/www/rails-skeleton/shared/tmp/pids/unicorn.pid"

stderr_path File.expand_path('log/unicorn.stderr.log', "/var/www/rails-skeleton/current")
stdout_path File.expand_path('log/unicorn.stdout.log', "/var/www/rails-skeleton/current")

preload_app true

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
  old_pid = "#{ server.config[:pid] }.oldbin"
  unless old_pid == server.pid
    begin
      Process.kill :QUIT, File.read(old_pid).to_i
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end
