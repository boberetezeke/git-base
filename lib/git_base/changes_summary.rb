module GitBase
  class ChangesSummary
    attr_reader :changes

    def initialize
      @changes = {}
    end

    def add(change)
      @changes[change.name] = change
    end

    def ==(other)
      return false unless other.is_a?(ChangesSummary)
      comps = @changes.map do |k, change|
        other.changes[k] == change
      end
      comps.select{|c| c}.size == @changes.keys.size
    end
  end
end
