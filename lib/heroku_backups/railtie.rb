require 'rails'

module HerokuBackups
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/heroku_backups.rake'
    end
  end
end
