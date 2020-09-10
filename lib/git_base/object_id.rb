module GitBase
  class ObjectId
    attr_reader :klass, :class_name, :id
    def initialize(klass, class_name, id)
      @klass = klass
      @class_name = class_name
      @id = id
    end
  end
end
