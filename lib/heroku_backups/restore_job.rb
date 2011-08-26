module HerokuBackups
  module RestoreJob
    @queue = :backups

    def self.perform(environment = nil, filename = nil)
      HerokuBackups::Backups.restore(environment, filename)
    end
  end
end