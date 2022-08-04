module GitBase
  class Result
    def initialize(command_type, result_type, details: {})
      @command_type = command_type
      @result_type = result_type
      @details = details
    end

    # Merge results
    def conflicts?
      @command_type == :merge && @result_type == :conflicts
    end
  end
end