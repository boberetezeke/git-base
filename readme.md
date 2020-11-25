### GitBase

This is a library to allow the storing of a database history
in git. Rows in the database are stored as single files with
one directory per table. The row's values are converted to
YAML and those YAML files are stored in git.

Start by creating a Database object

```
database = GitBase::Database.new("database_dir", "bin_dir")
```

Given a class..

```
class Person
  def self.from_attributes(attributes)
    new(attributes[:name], attributes[:id])
  end

  attr_accessor :name, :id
  def initialize(name, id)
    @name = name
    @id = id
  end

  def attributes
    {name: @name, id: @id}
  end
end
```

To save a person

```
person = Person.new("Bob", 25, 1)

object_guid = GitBase::ObjectGuid.new(Person, "person", person.id)
database.update(object_guid, person.attributes)

person.name = "Bobby"
database.update(object_guid, person.attributes)
```

To get the history of an object and display the changes

```
history = database.history(object_guid)

# most recent entry is first
second_version = history.entries.first  

# first entry is last
first_version = history.entries.last

first_version.changes_summary.changes.each do |change_name, change|
    puts "#{change.name}: from #{change.old_value} to #{change.new_value}"
    # results in:
    #   name: from nil to Bob
end

second_version.changes_summary.changes.each do |change_name, change|
    puts "#{change.name}: from #{change.old_value} to #{change.new_value}"
    # results in:
    #   name: from Bob to Bobby
end
```

To get the object as of a particular version

```
first_version_object = database.version_at(first_version)

puts first_version_object.name
# results in: Bob
```

To clone the database

```
cloned_database = database.clone("new-directory", "bin-directory")
```