BACKUP_BUCKET = 'outling-backup'

namespace :backups do
  desc "Restores db from s3 backup file"
  task :restore => :environment do
    HerokuBackups::Backups.restore(ENV['FILENAME'], ENV["RAILS_ENV"])
  end

  desc "Backs up db and uploads to s3"
  task :snapshot => :environment do
    HerokuBackups::Backups.snapshot
  end
end