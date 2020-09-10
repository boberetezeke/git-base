module GitBase
  class HistoryEntry
    attr_reader :sha, :author, :message, :file_entry, :time, :changes_summary

    def initialize(git_base, file_entry, json)
      @git_base = git_base
      @file_entry = file_entry
      @sha = json[:commit]
      @author = json[:author]
      @message = json[:message]
      @time = json[:date]
      @changes_summary = YAML::load(json[:changes_summary])
    end

    def retrieve
      @git_base.version_at(self)
    end
  end
end
