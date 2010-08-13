require 'rake'
require 'aws/s3'
require 'tasks/rake_helper'

BACKUP_BUCKET = 'YOUR_BUCKET_NAME'

namespace :db do
  
  desc "Restores db from s3 backup file"
  task :restore => [:environment, :reset] do
    if ENV['filename']
      filename = ENV['filename']
    else
      filename = s3_latest(BACKUP_BUCKET, 'bkp.')
    end

    puts "Begining restore of #{filename} @ #{Time.now}"
   
    timestamp = filename.split('.')[1]

    puts "Retrieving #{filename}..."
    s3_download(BACKUP_BUCKET, filename)

    puts "Decompressing backup..."
    `tar -xzf tmp/#{filename}`

    puts "Restoring database..."
    pg_restore(timestamp)

    puts "Cleaning up..."
    `rm tmp/#{timestamp}*`
    
  end

  desc "Backs up db and uploads to s3"
  task :backup => :environment do
    puts "Back up started @ #{Time.now}"
    timestamp = Time.now.to_i
    
    puts "Creating postgres dump..."
    pg_dump(timestamp)

    puts "Compressing backup..."
    tar_filename = "bkp.#{timestamp}.tar.gz"
    `tar -czf tmp/#{tar_filename} tmp/#{timestamp}*`

    puts "Uploading #{tar_filename} to S3..."
    s3_upload(BACKUP_BUCKET, "tmp/#{tar_filename}")
    puts "Cleaning up"
    `rm tmp/#{timestamp}*`

    puts "Done @ #{Time.now}"
  end

end
