require "yaml"
require "json"
require "tempfile"

module GitBase
  class Database
    def initialize(base_directory, bin_directory, initialize_if_doesnt_exist: true)
      @base_directory = File.expand_path(base_directory)
      @bin_directory = File.expand_path(bin_directory)

      initialize_git_directory(initialize_if_doesnt_exist)
    end

    #
    # Create an object GUID
    #
    # @param klass [Class] - the class of the object being stored
    # @param class_name [String] - an underscored version of the class name
    # @param guid [String] - the GUID of the object
    #
    def object_guid(*args)
      ObjectGuid.new(*args)
    end

    #
    # clone a git repository into another directory
    #
    # @param new_base_directory [String] - the base directory of the cloned repository
    # @param new_bin_directory [String] - the  bin directory of the cloned repository
    #
    def clone(new_base_directory, new_bin_directory)
      new_base_directory = File.expand_path(new_base_directory)
      new_bin_directory = File.expand_path(new_bin_directory)

      system("git clone #{@base_directory} #{new_base_directory}")
      self.class.new(new_base_directory, new_bin_directory)
    end

    #
    # merge branch into current branch
    #
    def merge(branch_name)
      Command.new(db_path).merge(branch_name)
    end

    #
    # fetch updates from remote
    #
    def fetch(remote_name)
      Command.new(db_path).fetch(remote_name)
    end

    def pull(remote_name, branch_name)
      Command.new(db_path).pull(remote_name, branch_name)
    end

    def push(remote_name, branch_name)
      Command.new(db_path).push(remote_name, branch_name)
    end

    #
    # switch to a branch
    #
    # @param branch_name [String] - the name of the branch to switch to
    #
    def switch_to_branch(branch_name, create: false)
      Command.new(db_path).checkout(branch_name, create: create)
    end

    #
    # tag the current branch with a tag name
    #
    # @param tag_name [String] - the name of the tag
    #
    def tag(tag_name)
      Command.new(db_path).tag(tag_name)
    end

    #
    # return the history of a given object
    #
    # @param object_guid [ObjectGuid|nil] - the object guid of the object
    # @param since [Time|String|nil] - a particular time, a tag name or all time
    # @return [History] - history object
    #
    def history(object_guid: nil, since: nil)
      json = Command.new(db_path).log(object_guid: object_guid, since: since)
      History.new(self, json)
    end

    #
    # Given a history entry, return the object as was at that time
    #
    # @param history_entry [HistoryEntry] - a history entry object
    # @return [Object] - The object
    #
    def version_at(history_entry)
      Dir.chdir(db_path) do
        file_entry =  FileEntry.new(history_entry.changes_summary.object_guid)
        attributes = YAML.load(StringIO.new(`git show #{history_entry.sha}:#{file_entry.relative_filename}`))

        file_entry.as_object(attributes)
      end
    end

    #
    # See if the git repository exists on disk
    #
    # @return [Boolean] - true if git repository exists
    #
    def exists?
      File.exist?(File.join(db_path, ".git"))
    end

    #
    # commit a change for an object to git
    #
    # @param object_guid [ObjectGuid] - the guid for the object
    # @param object_attributes [Hash] - a hash of attributes for the object
    #
    def update(object_guid, object_attributes)
      fe = FileEntry.new(object_guid)
      unless File.exist?(db_path)
        Dir.mkdir(db_path)
        Command.new(db_path).init
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
        diff = difference(object_guid, current_state, object_attributes)
        File.open(filename, "w") {|f| f.write object_attributes.to_yaml }
        commit_message_file = Tempfile.new("commit-message")
        begin
          commit_message_file.write diff.to_yaml
          commit_message_file.close
          Command.new(db_path).add(fe.relative_filename)
          Command.new(db_path).commit(commit_message_file.path)
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
    def difference(object_guid, current_state, new_state)
      diff = ChangesSummary.new(object_guid)
      new_state.each do |k,v|
        if current_state[k] != v
          diff.add(Change.new(k, current_state[k], v))
        end
      end

      diff
    end

    private

    GIT_BARE_CONTENTS = ["branches", "config", "description", "head", "hooks", "info", "objects", "refs"]
    #
    # initialize the database directory
    #
    # @param initialize_if_doesnt_exist [Boolean] - true if initialize if it doesn't exist
    #
    def initialize_git_directory(initialize_if_doesnt_exist)
      unless File.exist?(@base_directory)
        return unless initialize_if_doesnt_exist
        Dir.mkdir(@base_directory)
      end

      if FileTest.directory?(@base_directory)
        base_directory_contents = Dir["#{@base_directory}/*"].map{|fn| File.basename(fn).downcase}.sort
        return if base_directory_contents == GIT_BARE_CONTENTS

        git_directory = File.join(@base_directory, ".git")
        if File.exist?(git_directory)
          unless FileTest.directory?(git_directory)
            raise ".git directory is not a directory: #{git_directory}"
          end
        else
          if initialize_if_doesnt_exist
            Dir.chdir(@base_directory) do
              system("git init")
            end
          else
            raise ".git directory doesn't exist: #{git_directory}"
          end
        end
      else
        raise "base directory is not a directory: #{@base_directory}"
      end
    end

    #
    # the database base path
    #
    # @return [String] the database directory path
    #
    def db_path
      @base_directory
    end
  end
end
