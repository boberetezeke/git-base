module GitBase
  class FileEntry
    attr_reader :object_class_name, :object_guid
    def initialize(object_guid)
      @object_guid = object_guid
    end

    def relative_filename
      "#{@object_guid.class_name}/#{@object_guid.id}.yml"
    end

    def full_filename(db_path)
      "#{path_for_class(db_path)}/#{@object_guid.id}.yml"
    end

    def path_for_class(db_path)
      "#{db_path}/#{@object_guid.class_name}"
    end

    def as_object(attributes)
      @object_guid.klass.from_attributes(attributes)
    end
  end
end
