BACKUP_BUCKET = '<your backup bucket>'
ACCESS_KEY_ID = '<your aws access key id>'
SECRET_KEY    = '<your aws secret key>'

namespace :backups do

  desc "Restores db from s3 backup file"
  task :restore => [:environment, :reset] do
    require 'aws/s3'

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
  task :snapshot => :environment do
    require 'aws/s3'

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

  def get_db_settings
    matches = ENV['DATABASE_URL'].match(/postgres:\/\/([^:]+):([^@]+)@([^\/]+)\/(.+)/)
    {:username => matches[1], :password => matches[2], :host => matches[3], :db_name => matches[4]}
  end

  def pg_dump(timestamp)
    settings = get_db_settings
    filename = "tmp/#{timestamp}.pgdump"

    ENV['PGPASSWORD'] = settings[:password]
    `pg_dump -i -h #{settings[:host]} -U #{settings[:username]} -F c #{settings[:db_name]} > #{filename}`
    filename
  end

  def pg_restore(timestamp)
    settings = get_db_settings
    filename = "tmp/#{timestamp}.pgdump"

    ENV['PGPASSWORD'] = settings[:password]
    `pg_restore -i -O -x -h #{settings[:host]} -U #{settings[:username]} -d #{settings[:db_name]} #{filename}`
    # -O : no owner
    # -x : no privileges
  end

  def connect_s3!
    AWS::S3::Base.establish_connection!(
    :access_key_id => ACCESS_KEY,
    :secret_access_key => SECRET_KEY
    )
  end

  def s3_latest(bucket_name, prefix)
    connect_s3!
    objects = AWS::S3::Bucket.objects(bucket_name, :prefix => prefix)
    objects.last.path.split('/').last
  end

  def s3_download(bucket_name, file_name)
    connect_s3!

    open("tmp/#{file_name}", 'w') do |file|
      AWS::S3::S3Object.stream(file_name, bucket_name) do |chunk|
        file.write chunk
      end
    end

    file_name
  end

  def s3_upload(bucket_name, file_location)
    file_name = file_location.split('/').last
    connect_s3!

    begin
      bucket = AWS::S3::Bucket.find bucket_name
    rescue AWS::S3::NoSuchBucket
      AWS::S3::Bucket.create bucket_name
      bucket = AWS::S3::Bucket.find bucket_name
    end

    AWS::S3::S3Object.store file_name, File.read(file_location), bucket.name
  end
end