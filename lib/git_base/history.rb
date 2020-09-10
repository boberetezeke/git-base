module GitBase
  class History
    attr_reader :entries

    def initialize(git_base, file_entry, json)
      @git_base = git_base
      @file_entry = file_entry
      @json = json
      @entries = json.map{|j| HistoryEntry.new(git_base, file_entry, j)}
    end
  end
end
