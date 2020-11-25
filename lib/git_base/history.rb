module GitBase
  class History
    attr_reader :entries

    def initialize(git_base, json)
      @git_base = git_base
      @json = json
      @entries = json.map{|j| HistoryEntry.new(git_base, j)}
    end
  end
end
