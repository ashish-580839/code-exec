require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
# require 'mina/rbenv'  # for rbenv support. (https://rbenv.org)
require 'mina/rvm'    # for rvm support. (https://rvm.io)
require 'mina/puma'

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :application_name, 'code_exec'
set :domain, '149.129.129.87'
deploy_to = '/var/www/html'
set :deploy_to, deploy_to
set :repository, 'git@github.com:ashish-agrawal-metacube/code-exec.git'
set :branch, 'master'
# set :term_mode, nil
set :rvm_use_path, '/usr/local/rvm/scripts/rvm'

# Optional settings:
  set :user, 'root'          # Username in the server to SSH to.
# set :port, '22'           # SSH port number.
  set :forward_agent, true     # SSH forward_agent.
  set :identity_file, '/home/ashish/.ssh/code-exec-alibaba.pem'

# Shared dirs and files will be symlinked into the app-folder by the 'deploy:link_shared_paths' step.
# Some plugins already add folders to shared_dirs like `mina/rails` add `public/assets`, `vendor/bundle` and many more
# run `mina -d` to see all folders and files already included in `shared_dirs` and `shared_files`
set :shared_dirs, fetch(:shared_dirs, []).push('log','tmp/pids', 'tmp/sockets')
set :shared_files, fetch(:shared_files, []).push( 'config/application.yml')

# This task is the environment that is loaded for all remote run commands, such as
# `mina deploy` or `mina rake`.
task :remote_environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  invoke :'rvm:use', 'ruby-2.5.0@default'
end

# Put any custom commands you need to run at setup
# All paths in `shared_dirs` and `shared_paths` will be created on their own.
task :setup do
  # command %{rbenv install 2.3.0 --skip-existing}
  command %[mkdir -p "#{deploy_to}/shared/log"]
  command %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  command %[mkdir -p "#{deploy_to}/shared/config"]
  command %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]

  command %[mkdir -p "#{deploy_to}/shared/tmp"]
  command %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp"]

  command %[mkdir -p "#{deploy_to}/shared/tmp/sockets"]
  command %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/sockets"]

  command %[mkdir -p "#{deploy_to}/shared/tmp/pids"]
  command %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/pids"]

  command %[touch "#{deploy_to}/shared/config/application.yml"]
end

desc "Deploys the current version to the server."
task :deploy do
  # uncomment this line to make sure you pushed your local branch to the remote origin
  # invoke :'git:ensure_pushed'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    comment "Deploying #{fetch(:application_name)} to #{fetch(:domain)}:#{fetch(:deploy_to)}"
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    # invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    on :launch do
       invoke :'puma:phased_restart'
    end
  end

  # you can use `run :local` to run tasks on local machine before of after the deploy scripts
  # run(:local){ say 'done' }
end

# For help in making your deploy script, see the Mina documentation:
#
#  - https://github.com/mina-deploy/mina/tree/master/docs
