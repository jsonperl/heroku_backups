module HerokuBackups
  class Database
    def self.db_settings
      remote = ENV['DATABASE_URL']

      if remote
        matches = ENV['DATABASE_URL'].match(/postgres:\/\/([^:]+):([^@]+)@([^\/]+)\/(.+)/)
        settings = {:username => matches[1], :password => matches[2], :host => matches[3], :db_name => matches[4]}
      else
        db_options = YAML.load_file(File.join(Rails.root, 'config', 'database.yml'))[Rails.env].symbolize_keys
        settings = {:username => db_options[:username], :password => db_options[:password], :host => db_options[:hostname], :db_name => db_options[:database]}
      end

      settings
    end

    def self.dump(timestamp)
      settings = db_settings
      filename = "tmp/#{timestamp}.pgdump"

      ENV['PGPASSWORD'] = settings[:password] if settings[:password]
      user = settings[:username] ? "-U #{settings[:username]} " : ''

      `pg_dump -i -h #{settings[:host]} #{user}-F c #{settings[:db_name]} > #{filename}`
      filename
    end

    def self.restore(timestamp)
      settings = db_settings
      filename = "tmp/#{timestamp}.pgdump"

      ENV['PGPASSWORD'] = settings[:password] if settings[:password]
      user = settings[:username] ? "-U #{settings[:username]} " : ''
      host = settings[:host] ? "-h #{settings[:host]} " : ''

      `pg_restore --verbose --clean --no-acl --no-owner #{host}#{user}-d #{settings[:db_name]} #{filename}`
    end

    def self.drop_tables
      ActiveRecord::Base.connection.tables.each do |table_name|
        ActiveRecord::Base.connection.execute("DROP TABLE #{table_name}")
      end
    end
  end
end