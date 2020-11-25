require_relative "./spec_helper"
require_relative "../lib/git_base"

class Widget
  attr_reader :attributes
  def self.from_attributes(attributes)
    new(attributes)
  end

  def initialize(attributes)
    @attributes = attributes
  end
end

describe GitBase::Database do
  GIT_ROOT = "git_root"
  GIT_BIN_DIR = "bin"

  before do
    Dir.mkdir(GIT_ROOT)
    Dir.chdir(GIT_ROOT) do
      system("git init")
    end
  end

  after do
    system("rm -rf #{GIT_ROOT}")
  end

  it "writes to git" do
    git = GitBase::Database.new(GIT_ROOT, GIT_BIN_DIR)

    attributes = {color: "red", size: 1}
    git.update(git.object_guid(Widget, "widget", "abcd"), attributes)

    expect(YAML.load(File.read("#{GIT_ROOT}/widget/abcd.yml"))).to eq(attributes)
  end

  it "returns history of changes with multiple objects" do
    git = GitBase::Database.new(GIT_ROOT, GIT_BIN_DIR)
    git_oid_1 = git.object_guid(Widget, "widget", "1")
    git_oid_2 = git.object_guid(Widget, "widget", "2")

    attributes = {color: "red", size: 1}
    git.update(git_oid_1, attributes)

    attributes = {color: "orange", size: 3}
    git.update(git_oid_2, attributes)

    attributes = {color: "blue", size: 2}
    git.update(git_oid_1, attributes)

    history = git.history

    expect(history.entries.size).to eq(3)

    expect(history.entries[0].class).to eq(GitBase::HistoryEntry)
    changes_summary_expected = GitBase::ChangesSummary.new(git_oid_1)
    changes_summary_expected.add(GitBase::Change.new(:color, "red", "blue"))
    changes_summary_expected.add(GitBase::Change.new(:size, 1, 2))
    expect(history.entries[0].changes_summary).to eq(changes_summary_expected)

    expect(history.entries[1].class).to eq(GitBase::HistoryEntry)
    changes_summary_expected = GitBase::ChangesSummary.new(git_oid_2)
    changes_summary_expected.add(GitBase::Change.new(:color, nil, "orange"))
    changes_summary_expected.add(GitBase::Change.new(:size, nil, 3))
    expect(history.entries[1].changes_summary).to eq(changes_summary_expected)

    expect(history.entries[2].class).to eq(GitBase::HistoryEntry)
    changes_summary_expected = GitBase::ChangesSummary.new(git_oid_1)
    changes_summary_expected.add(GitBase::Change.new(:color, nil, "red"))
    changes_summary_expected.add(GitBase::Change.new(:size, nil, 1))
    expect(history.entries[2].changes_summary).to eq(changes_summary_expected)
  end

  it "returns history of changes with multiple objects since a tag was applied" do
    git = GitBase::Database.new(GIT_ROOT, GIT_BIN_DIR)
    git_oid_1 = git.object_guid(Widget, "widget", "1")
    git_oid_2 = git.object_guid(Widget, "widget", "2")

    attributes = {color: "red", size: 1}
    git.update(git_oid_1, attributes)

    git.tag("my-tag")

    attributes = {color: "orange", size: 3}
    git.update(git_oid_2, attributes)

    attributes = {color: "blue", size: 2}
    git.update(git_oid_1, attributes)

    history = git.history(since: "my-tag")

    expect(history.entries.size).to eq(2)

    expect(history.entries[0].class).to eq(GitBase::HistoryEntry)
    changes_summary_expected = GitBase::ChangesSummary.new(git_oid_1)
    changes_summary_expected.add(GitBase::Change.new(:color, "red", "blue"))
    changes_summary_expected.add(GitBase::Change.new(:size, 1, 2))
    expect(history.entries[0].changes_summary).to eq(changes_summary_expected)

    expect(history.entries[1].class).to eq(GitBase::HistoryEntry)
    changes_summary_expected = GitBase::ChangesSummary.new(git_oid_2)
    changes_summary_expected.add(GitBase::Change.new(:color, nil, "orange"))
    changes_summary_expected.add(GitBase::Change.new(:size, nil, 3))
    expect(history.entries[1].changes_summary).to eq(changes_summary_expected)
  end

  it "returns history objects after two writes" do
    git = GitBase::Database.new(GIT_ROOT, GIT_BIN_DIR)
    git_oid = git.object_guid(Widget, "widget", "abcd")

    attributes = {color: "red", size: 1}
    git.update(git_oid, attributes)

    attributes = {color: "blue", size: 2}
    git.update(git_oid, attributes)

    history = git.history(object_guid: git_oid)

    expect(history.entries.size).to eq(2)
    expect(history.entries.first.class).to eq(GitBase::HistoryEntry)
    changes_summary_expected = GitBase::ChangesSummary.new(git_oid)
    changes_summary_expected.add(GitBase::Change.new(:color, "red", "blue"))
    changes_summary_expected.add(GitBase::Change.new(:size, 1, 2))
    expect(history.entries.first.changes_summary).to eq(changes_summary_expected)
  end

  it "returns a particular version of an object" do
    git = GitBase::Database.new(GIT_ROOT, GIT_BIN_DIR)
    git_oid = git.object_guid(Widget, "widget", "abcd")

    attributes = {color: "red", size: 1}
    git.update(git_oid, attributes)
    # attributes = {color: "blue", size: 2}
    # git.update(git_oid, attributes)

    # history = git.history(object_guid: git_oid)

    # expect(history.entries[0].retrieve.attributes).to eq({color: "blue", size: 2})
    # expect(history.entries[1].retrieve.attributes).to eq({color: "red", size: 1})
  end
end