module GitBase
  class HistoryEntry
    # Git SHA for the commit containing this entry
    attr_reader :sha
    # The email address of the author as a String
    attr_reader :author
    # The commit message
    attr_reader :message
    # Time - the time of the change
    attr_reader :time
    # [Symbol, Change] - the symbol for the field that changed and the change description object
    attr_reader :changes_summary

    def initialize(git_base, json)
      @git_base = git_base
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
