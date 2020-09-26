require "yaml"
require "json"
require "tempfile"

module GitBase
  class Database
    def initialize(base_directory, bin_directory)
      @base_directory = File.expand_path(base_directory)
      @bin_directory = File.expand_path(bin_directory)
    end

    def object_id(*args)
      ObjectId.new(*args)
    end

    #
    # return the history of a given object
    #
    # @param object_id [ObjectId] - the object id of the object
    # @return [History] - history object
    #
    def history(object_id)
      json = nil

      file_entry = FileEntry.new(object_id)
      Dir.chdir(db_path) do
        output = `git log #{file_entry.relative_filename}`.split(/\n/)
        json = parse_history(output)
      end

      History.new(self, file_entry, json)
    end

    #
    # Given a history entry, return the object as was at that time
    #
    # @param history_entry [HistoryEntry] - a history entry object
    # @return [Object] - The object
    #
    def version_at(history_entry)
      attributes = nil
      Dir.chdir(db_path) do
        attributes = YAML.load(StringIO.new(`git show #{history_entry.sha}:#{history_entry.file_entry.relative_filename}`))
      end
      history_entry.file_entry.as_object(attributes)
    end

    #
    # commit a change for an object to git
    #
    # @param object_id [ObjectId] - the id for the object
    # @param object_attributes [Hash] - a hash of attributes for the object
    #
    def update(object_id, object_attributes)
      fe = FileEntry.new(object_id)
      unless File.exist?(db_path)
        Dir.mkdir(db_path)
        Dir.chdir(db_path) do
          system("git init")
        end
      end

      unless File.directory?(db_path)
        puts "Warning: Unable to save file because file #{db_path} is not a directory as db path"
        return
      end

      Dir.mkdir(fe.path_for_class(db_path)) unless File.exist?(fe.path_for_class(db_path))

      if File.directory?(fe.path_for_class(db_path))
        filename = fe.full_filename(db_path)
        if File.exist?(filename)
          current_state = YAML.load(File.read(filename))
        else
          current_state = {}
        end
        diff = difference(current_state, object_attributes)
        File.open(filename, "w") {|f| f.write object_attributes.to_yaml }
        commit_message_file = Tempfile.new("commit-message")
        begin
          commit_message_file.write diff.to_yaml
          commit_message_file.close
          Dir.chdir(db_path) do
            system("git add #{fe.relative_filename}")
            system("git commit --file #{commit_message_file.path}")
          end
        ensure
          commit_message_file.unlink
        end
      else
        puts "Warning: Unable to save file because file #{fe.path_for_class(db_path)} is not a directory json file"
      end
    end

    #
    # return a change based on the current and new states??
    #
    # @param
    def difference(current_state, new_state)
      diff = ChangesSummary.new
      new_state.each do |k,v|
        if current_state[k] != v
          diff.add(Change.new(k, current_state[k], v))
        end
      end

      diff
    end

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

    def db_path
      @base_directory
    end
  end
end
