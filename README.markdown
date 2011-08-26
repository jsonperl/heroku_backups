# Heroku Backups Gem for Rails 3
## Amazon S3 Backup and Restore capabilities for your Heroku app

### Things you can do:
* Run automated backups (via cron, or Resque)
* Restore your database from a point in time backup
* Move an entire database from one environment to another
* Restore your production database to your development machine

### Installation
Place in your Gemfile:

    gem 'heroku_backups'

Place a file name amazon_s3.yml in your config folder:

    production:
      bucket: yourapp-production
      access_key_id: your-key
      secret_access_key: your-secret
    staging:
      bucket: yourapp-staging
      access_key_id: your-key
      secret_access_key: your-secret
    development:
      bucket: yourapp-staging
      access_key_id: your-key
      secret_access_key: your-secret


## Rake Tasks
* backups:snapshot # Snapshots the current environment's database and stores on S3
* backups:restore  # Restores the latest production backup to your current environment
* backups:restore FILENAME=bkp.1273533572.tar.gz # Restores this backup file from production to your current environment
* backups:restore RAILS_ENV=staging # Restores the latest staging backup from to your current environment
* heroku rake backups:snapshot --app from_application # Snapshot a particular heroku app
* heroku rake backups:restore --app to_application # Restore from production to a particular heroku app
* heroku rake backups:restore filename=bkp.1273533572.tar.gz --app to_application # Restore a backup file to a particular heroku app

## Resque Jobs
Since snapshots and restores can potentially be long operations, two Resque jobs have been provided:

    Resque.enqueue(HerokuBackups::SnapshotJob)
    Resque.enqueue(HerokuBackups::RestoreJob, environment, filename)

environment and filename are optional parameters and instruct the job which backup file to restore and from which environment

## Automate backups
Place something like the following task (or add to it) in your lib/tasks/cron.rake

    desc "Cron fights for the users"
    task :cron => :environment do
      HerokuBackups::Backups.snapshot if Time.now.hour == 2 # runs at 2am
    end

or better yet, drop a Resque job!

    desc "Cron fights for the users"
    task :cron => :environment do
      Resque.enqueue(HerokuBackups::SnapshotJob) if Time.now.hour % 4 # runs every 4 hours
    end

## OH $h!t, I need to Restore
Use the backups:restore rake task or to avoid your long running job from getting killed, connect to heroku console and:

    Resque.enqueue(HerokuBackups::RestoreJob)