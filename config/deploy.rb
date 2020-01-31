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
