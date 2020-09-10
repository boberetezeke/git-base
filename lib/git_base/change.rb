module GitBase
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
end
