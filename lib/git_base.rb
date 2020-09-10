require "yaml"
require "json"
require "tempfile"

class GitBase
  class ObjectId
    attr_reader :klass, :class_name, :id
    def initialize(klass, class_name, id)
      @klass = klass
      @class_name = class_name
      @id = id
    end
  end

  class Change
    OLD_NEW = 'old_new'

    attr_reader :name, :old_value, :new_value, :change_type, :complete
    def initialize(name, old_value, new_value, change_type: OLD_NEW, complete: true)
      @name = name
      @old_value = old_value
      @new_value = new_value
      @change_type = change_type
      @complete = complete
    end

    def ==(other)
      @name == other.name &&
      @old_value == other.old_value &&
      @new_value == other.new_value &&
      @change_type == other.change_type &&
      @complete == other.complete
    end
  end

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

  class History
    attr_reader :entries

    def initialize(git_base, file_entry, json)
      @git_base = git_base
      @file_entry = file_entry
      @json = json
      @entries = json.map{|j| HistoryEntry.new(git_base, file_entry, j)}
    end
  end

  class FileEntry
    attr_reader :object_class_name, :object_id
    def initialize(object_id)
      @object_id = object_id
    end

    def relative_filename
      "#{@object_id.class_name}/#{@object_id.id}.yml"
    end

    def full_filename(db_path)
      "#{path_for_class(db_path)}/#{@object_id.id}.yml"
    end

    def path_for_class(db_path)
      "#{db_path}/#{@object_id.class_name}"
    end

    def as_object(attributes)
      @object_id.klass.new(attributes)
    end
  end

  def initialize(base_directory, bin_directory)
    @base_directory = File.expand_path(base_directory)
    @bin_directory = File.expand_path(bin_directory)
  end

  def object_id(*args)
    ObjectId.new(*args)
  end

  def history(object_id)
    json = nil

    file_entry = FileEntry.new(object_id)
    Dir.chdir(db_path) do
      output = `git log #{file_entry.relative_filename}`.split(/\n/)
      json = parse_history(output)
    end

    History.new(self, file_entry, json)
  end

  def version_at(history_entry)
    attributes = nil
    Dir.chdir(db_path) do
      attributes = YAML.load(StringIO.new(`git show #{history_entry.sha}:#{history_entry.file_entry.relative_filename}`))
    end
    history_entry.file_entry.as_object(attributes)
  end

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