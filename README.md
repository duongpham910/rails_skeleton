# RAILS SKELETON

## Build environment

### Development (Docker)

1. Clone and enter project's folder

   ```console
   git clone # using SSH or HTTPS method
   cd rails_skeleton
   ```

2. Config database and credentials

   ```console
   cp config/database.yml.example config/database.yml
   cp config/master.key.example config/master.key
   ```

3. Create MYSQL config file

   ```console
   touch docker/my.cnf
   ```

4. Build and run docker

   a. Builds, (re)creates, starts, and attaches to containers for a service

   ```console
   chmod +x ./docker/scripts/docker-entrypoint.sh
   docker-compose up -d && docker attach $(docker-compose ps -q web)
   ```

   b. Open docker container bash

   Open new tab in terminal

   ```console
   docker-compose exec web bash
   ```

   c. Generate dummy data.

   ```console
   rails db:create db:migrate
   ```
5. When docker is running, open <http://localhost:3001>

## Code Quality Assurance

Run each of these commands then fix any problem that appears

```console
rubocop
rails_best_practices .
brakeman
```

## Deployment

1. Set up environment (Ruby, Nodejs, MySQL, Yarn, Nginx) on EC2 server

2. Update source code

   Add this gem to gem file:

   ```console
   gem "unicorn"

   #development group
   gem "capistrano"
   gem "capistrano-bundler"
   gem "capistrano-rails"
   gem "capistrano-rvm"
   gem "capistrano-yarn"
   ```

   a. Generate file cap with this command: `bundle exec cap install`. Open capfile and uncomment these require below

   ```console
   require "capistrano/rvm"
   require "capistrano/bundler"
   require "capistrano/rails"
   require "capistrano/rails/assets"
   require "capistrano/rails/migrations"
   require "capistrano/yarn"
   ```

   b. Next thing is update file `config/deploy.rb`

   ```console
    # config valid for current version and patch releases of Capistrano
    lock "~> 3.11.2"

    set :application, "rails-skeleton"
    set :keep_releases, 5
    set :bundle_without, [:development, :test]
    set :repo_url, "git://github.com/duongpham910/rails_skeleton.git"
    set :deploy_to, "/var/www/rails-skeleton"
    set :yarn_flags, "--production --check-files"
    set :linked_files, %w[config/master.key config/database.yml]
    set :linked_dirs, %w[log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/packs node_modules]

    namespace :deploy do
      desc "link dotenv"
      task :link_dotenv do
        on roles(:app) do
          execute "ln -s /home/deploy/.env #{release_path}/.env"
        end
      end
      before "deploy:assets:precompile", "deploy:link_dotenv"

      desc "Stop application"
      task :stop_app do
        on roles(:app) do
          execute "/etc/init.d/unicorn_rails_skeleton stop"
        end
      end
      desc "Start application"
      task :start_app do
        on roles(:app) do
          within current_path do
            execute :bundle, "exec unicorn", "-c", "config/unicorn.rb", "-E", fetch(:stage), "-D"
          end
        end
      end
      before :publishing, :stop_app
      after :finished, :start_app
    end
   ```

   c. Depent on what kind of deployment env(in this case is staging). Open file `config/deploy/staging.rb`

   ```console
    set :user, "ubuntu"
    set :stage, :staging
    set :ssh_options, {
         keys: %w(~/.ssh/rails-skeleton-key.pem),
         forward_agent: false,
         auth_methods: %w(publickey)
    }

    # Pass varibale to deploy from different git branches
    set :deploy_ref, ENV["DEPLOY_REF"]
    if fetch(:deploy_ref)
      set :branch, fetch(:deploy_ref)
    else
      set :branch, "develop"
    end

    # Setup IP with ec2 server
    server "3.91.132.132", user: fetch(:user), roles: %w[app web]
   ```

   d. Checking capistrano can work or not with this command `bundle exec cap staging deploy:check`

   e. Copy file from local to server

   ```console
    scp -i "~/.ssh/rails-skeleton-key.pem" master.key ubuntu@3.91.132.132:/var/www/rails-skeleton/shared/config
    #remember to add staging env into yml file
    scp -i "~/.ssh/rails-skeleton-key.pem" database.yml ubuntu@3.91.132.132:/var/www/rails-skeleton/shared/config
   ```

   f. Create new file `config/unicorn`

    ```console
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

    ```

   g. Change file `config/webpacker.yml ` if project was created with webpack option

   ```console
   staging:
     <<: *default
     # Production depends on precompilation of packs prior to booting for performance.
     compile: false
     # Extract and emit a css file
     extract_css: true
     # Cache manifest.json for performance
     cache_manifest: true
   ```

   h. Final thing need to check is `config/environments/staging.rb`. Check if file exits, setup mail env...

3. Nginx and unicorn configuration on EC2 server

   a. Inside folder `/etc/init.d/` you can start/restart/reload/stop unicorn by create new file `vi /etc/init.d/unicorn_rails_skeleton` and change like below:

    ```console
    #!/bin/sh
    set -u
    set -e
    # Example init script, this can be used with nginx, too,
    # since nginx and unicorn accept the same signals
    #[[ -s '/usr/local/rvm/scripts/rvm' ]] && source '/usr/local/rvm/scripts/ rvm'

    # Feel free to change any of the following variables for your app:
    USER=ubuntu
    GEM_HOME=/var/www/rails-skeleton/shared/bundle
    APP_ROOT=/var/www/rails-skeleton/current
    SET_PATH="export GEM_HOME=$GEM_HOME"

    PID="$APP_ROOT/tmp/pids/unicorn.pid"
    ENV="staging"
    CMD="$SET_PATH; cd $APP_ROOT && bundle exec unicorn -D -E $ENV -c $APP_ROOT/config/unicorn.rb"
    old_pid="$PID.oldbin"

    #cd $APP_ROOT || exit 1
    $SET_PATH || exit 1

    sig () {
      test -s "$PID" && kill -$1 `cat $PID`
    }

    oldsig () {
      test -s $old_pid && kill -$1 `cat $old_pid`
    }

    case $1 in
    start)
      sig 0 && echo >&2 "Already running" && exit 0
      su - $USER -c "$CMD"
      ;;
    stop)
      sig QUIT && exit 0
      echo >&2 "Not running"
      ;;
    force-stop)
      sig TERM && exit 0
      echo >&2 "Not running"
      ;;
    restart|reload)
      sig HUP && echo reloaded OK && exit 0
      echo >&2 "Couldn't reload, starting '$CMD' instead"
      su - $USER -c "$CMD"
      ;;
    upgrade)
      sig USR2 && echo upgraded OK && exit 0
      echo >&2 "Couldn't upgrade, starting '$CMD' instead"
      su - $USER -c "$CMD"
      ;;
    rotate)
      sig USR1 && echo rotated logs OK && exit 0
      echo >&2 "Couldn't rotate logs" && exit 1
      ;;
    *)
      echo >&2 "Usage: $0 <start|stop|restart|upgrade|rotate|force-stop>"
      exit 1
      ;;
    esac

    ```

   b. After save file, you must give permission for executable

    ```console
    sudo chmod +x /etc/init.d/unicorn_rails_skeleton
    ```

   c. After that we move to config NginX. Go to `/etc/nginx/sites-available/` and backup file default with `cp default default.bak` then change file default content:

    ```console
    upstream unicorn_1 {
      server unix:/var/www/rails-skeleton/shared/tmp/unicorn.sock fail_timeout=0;
    }

    server {
      listen 80;
      server_tokens off;
      add_header X-Content-Type-Options nosniff;
      client_max_body_size 40G;
      keepalive_timeout 150;
      error_page 500 502 504 /500.html;
      error_page 503 @503;

      server_name _;
      root /var/www/rails-skeleton/current/public;
      try_files $uri/index.html $uri @unicorn;
      location @unicorn {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
        proxy_pass http://unicorn_1;
      }
      location ^~ /assets/ {
          gzip_static on;
          expires max;
          add_header Cache-Control public;
      }
      location ^~ /packs/ {
          gzip_static on;
          expires max;
          add_header Cache-Control public;
      }

      location = /50x.html {
          root html;
      }

      location = /404.html {
          root html;
      }

      location @503 {
          error_page 405 = /system/maintenance.html;
          if (-f $document_root/system/maintenance.html) {
              rewrite ^(.*)$ /system/maintenance.html break;
          }
          rewrite ^(.*)$ /503.html break;
      }

      if ($request_method !~ ^(GET|HEAD|PUT|PATCH|POST|DELETE|OPTIONS)$ ){
          return 405;
      }

      if (-f $document_root/system/maintenance.html) {
          return 503;
      }
    }
    ```

   d. After save file restart nginx with command:

   ```console
   sudo service nginx restart
   ```

4. Deploy to server from local

   a. Deploy branch staging to develop-server

    ```console
    bundle exec cap staging deploy
    ```

   b. Deploy branch A to develop-server

    ```console
    bundle exec cap staging deploy DEPLOY_REF=A
    ```

   c. Note

   Check log if any problem that appears or run from local with this command to debug

    ```console
    RAILS_ENV=staging bundle exec rails db:create
    RAILS_ENV=staging bundle exec rails assets:precompile
    RAILS_ENV=staging bundle exec rails s
    ```
