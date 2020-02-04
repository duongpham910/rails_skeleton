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
