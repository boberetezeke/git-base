module GitBase
  class Command
    def initialize(db_path)
      @db_path = db_path
    end

    def init
      run("init")
    end

    def add(filename)
      run("add #{filename}")
    end

    def commit(commit_message_file_path)
      run("commit --file #{commit_message_file_path}")
    end

    def checkout(branch_name)
      run("checkout #{branch_name}")
    end

    def tag(tag_name)
      run("tag #{tag_name}")
    end

    def log(object_guid: nil, since: nil)
      json = nil
      Dir.chdir(@db_path) do
        commands =  ["git log"] +
          (since ? ["#{since}..HEAD"] : []) +
          (object_guid ? [FileEntry.new(object_guid).relative_filename] : [])
        command = commands.join(" ")

        output = `#{command}`.split(/\n/)
        json = (output == []) ? [] : parse_history(output)
      end
      json
    end

    private

    def run(str)
      Dir.chdir(@db_path) do
        system("git #{str} > /dev/null")
      end
    end

    #
    # Parse the history from the output of the "git log" command
    #
    # @param [String] - the "git log" output
    # @return [Array<Hash<Symbol,_>>] - An array of entries where each entry is a Hash
    #   with the following keys and values:
    #     :message - [String] - the commit message
    #     :changes_summary - [String] - the ChangesSummary object as YAML
    #     :author - [String] - the author's email
    #     :date - [String] - the date in some format
    #
    def parse_history(output)
      json = []
      entry = {}
      yaml = ""
      message = ""
      output.each do |line|
        line.chomp!
        case line
        when /^commit (.*)$/
          unless entry.empty?
            entry[:message] = message
            entry[:changes_summary] = yaml
            json.push(entry)
            entry = {}
            yaml = ""
            message = ""
          end
          entry[:commit] = $1
        when /^Author: (.*)/
          entry[:author] = $1
        when /^Date: (.*)/
          entry[:date] = $1
        else
          message << line + "\n"
          if line.size >= 4
            yaml << line[4..-1] + "\n"
          end
        end
      end
      entry[:message] = message
      entry[:changes_summary] = yaml
      json.push(entry)
      # output = `bash #{@bin_directory}/log-history.sh #{file_entry.relative_filename}`
      # json = JSON.parse(output)

      json
    end
  end
end
