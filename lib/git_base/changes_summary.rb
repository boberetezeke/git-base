module GitBase
  class ChangesSummary
    attr_reader :changes, :object_guid

    def initialize(object_guid)
      @object_guid = object_guid
      @changes = {}
    end

    def add(change)
      @changes[change.name] = change
    end

    def ==(other)
      return false unless other.is_a?(ChangesSummary)
      return false unless @object_guid == self.object_guid
      comps = @changes.map do |k, change|
        other.changes[k] == change
      end
      comps.select{|c| c}.size == @changes.keys.size
    end
  end
end
