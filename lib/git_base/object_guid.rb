module GitBase
  class ObjectGuid
    attr_reader :klass, :class_name, :id

    #
    # Create an object GUID
    #
    # @param klass [Class] - the class of the object being stored
    # @param class_name [String] - an underscored version of the class name
    # @param id [String] - the ID of the object
    #
    def initialize(klass, class_name, id)
      @klass = klass
      @class_name = class_name
      @id = id
    end
  end
end
