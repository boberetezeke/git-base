module GitBase
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
end
