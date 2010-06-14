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
  `pg_restore -c -O -x -h #{settings[:host]} -U #{settings[:username]} -d #{settings[:db_name]} #{filename}`
  # -c : clean
  # -O : no owner
  # -x : no privileges
end

def connect_s3!
  config = YAML.load(File.open("#{RAILS_ROOT}/config/amazon_s3.yml"))[RAILS_ENV]
  AWS::S3::Base.establish_connection!(
    :access_key_id => config['access_key_id'],
    :secret_access_key => config['secret_access_key']
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