module HerokuBackups
  module SnapshotJob
    @queue = :backups

    def self.perform
      Backups.snapshot
    end
  end
end