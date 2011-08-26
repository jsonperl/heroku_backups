module HerokuBackups
  require 'aws/s3'

  class S3
    def self.connect(environment)
      AWS::S3::Base.establish_connection!(
        :access_key_id => settings(environment)[:access_key_id],
        :secret_access_key => settings(environment)[:secret_access_key]
      )
    end

    def self.latest_backup(environment)
      connect(environment)
      objects = AWS::S3::Bucket.objects(settings(environment)[:bucket], :prefix => "backups/bkp.")
      raise "No backups found in #{environment} environment" if objects.count == 0

      objects.last.path.split('/').last
    end

    def self.download(environment, file_name)
      connect(environment)
      target_file = file_name.split('/').last

      open("tmp/#{target_file}", 'w+b', 0644) do |file|
        AWS::S3::S3Object.stream(file_name, settings(environment)[:bucket]) do |chunk|
          file.write chunk
        end
      end

      file_name
    end

    def self.upload(file_location)
      file_name = file_location.split('/').last
      bucket_name = settings(Rails.env)[:bucket]
      
      connect(Rails.env)

      begin
        bucket = AWS::S3::Bucket.find bucket_name
      rescue AWS::S3::NoSuchBucket
        AWS::S3::Bucket.create bucket_name, :access => :private
        bucket = AWS::S3::Bucket.find bucket_name
      end

      AWS::S3::S3Object.store "backups/#{file_name}", File.read(file_location), bucket.name, :access => :private
    end

    private

    def self.settings(environment)
      @settings ||= {}
      @settings[environment.to_sym] ||= YAML.load(File.open("#{Rails.root}/config/amazon_s3.yml"))[environment.to_s].symbolize_keys
    end
  end
end