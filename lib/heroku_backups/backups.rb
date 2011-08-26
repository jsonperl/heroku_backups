module HerokuBackups
  require 'aws/s3'

  class Backups
    BACKUP_BUCKET = 'outling-backup'

    def self.snapshot
      puts "Back up started @ #{Time.now}"

      timestamp = Time.now.to_i

      status_message "Creating postgres dump..."
      Database.dump(timestamp)

      status_message "Compressing backup..."
      tar_filename = "bkp.#{timestamp}.tar.gz"
      `tar -czf tmp/#{tar_filename} tmp/#{timestamp}*`

      status_message "Uploading #{tar_filename} to S3..."
      S3.upload("tmp/#{tar_filename}")

      status_message "Cleaning up"
      `rm tmp/#{timestamp}*`

      status_message "Done @ #{Time.now}"
    end

    def self.restore(from_environment=nil, filename=nil)
      status_message "Restore started @ #{Time.now}"

      from_environment ||= 'production'
      
      filename = S3.latest_backup(from_environment) unless filename
      timestamp = filename.split('.')[1]
      
      status_message "Retrieving #{filename} from #{from_environment}..."
      S3.download(from_environment, "backups/#{filename}")

      status_message "Decompressing backup..."
      `tar -xzf tmp/#{filename}`

      status_message "Dropping tables..."
      Database.drop_tables

      status_message "Restoring database..."
      Database.restore(timestamp)

      status_message "Cleaning up..."
      `rm tmp/#{timestamp}*`

      status_message "Done @ #{Time.now}"
    end

    def self.status_message(message)
      puts message
    end
  end
end
