class Git::ExerciseReader

  attr_reader :repo, :exercise_slug, :commit, :config
  def initialize(repo, exercise_slug, commit, config)
    @repo = repo
    @exercise_slug = exercise_slug
    @commit = commit
    @config = config
  end

  def readme
    readme_ptr = exercise_tree['README.md']
    return nil if readme_ptr.nil?
    blob = repo.lookup(readme_ptr[:oid])
    blob.text
  rescue => e
    puts e.message
    puts e.backtrace
    ""
  end

  def tests
    files = exercise_files.select { |f| f[:name].match(test_pattern) }
    test_suites = {}
    files.each do |file|
      name = file[:name]
      blob = repo.lookup(file[:oid])
      test_suites[name] = blob.text
    end
    test_suites
  rescue => e
    puts e.message
    puts e.backtrace
    nil
  end

  def solution
    meta_ptr = exercise_tree[".meta"]
    return nil if meta_ptr.nil?
    meta_tree = repo.lookup(meta_ptr[:oid])
    solutions_ptr = meta_tree["solutions"]
    return nil if solutions_ptr.nil?
    solutions_tree = repo.lookup(solutions_ptr[:oid])
    first_file = solutions_tree.first
    return nil if first_file.nil?
    blob = repo.lookup(first_file[:oid])
    blob.text
  rescue => e
    puts e.message
    puts e.backtrace
    ""
  end

  def blurb
    meta_ptr = exercise_tree[".meta"]
    return nil if meta_ptr.nil?
    meta_tree = repo.lookup(meta_ptr[:oid])
    metadata_ptr = meta_tree["metadata.yml"]
    return nil if metadata_ptr.nil?
    metadata_yml = repo.lookup(metadata_ptr[:oid])
    metadata = YAML.load(metadata_yml.text).symbolize_keys
    metadata[:blurb]
  rescue => e
    puts e.message
    puts e.backtrace
    nil
  end

  private

  def test_pattern
    pattern = config[:test_pattern]
    return /test/i if pattern.nil?
    Regexp.new(pattern)
  end

  def exercise_files
    @exercise_files ||= begin
      exercise_files = []
      exercise_tree.walk(:preorder) do |r, t|
        path = "#{r}#{t[:name]}"
        t[:full] = path
        exercise_files.push(t) unless path.start_with?(".meta")
      end
      exercise_files
    end
  end

  def tree
    commit.tree
  end

  def exercise_tree
    oid = tree['exercises'][:oid]
    t = repo.lookup(oid)
    entry = t[exercise_slug]
    oid = entry[:oid]
    repo.lookup(oid)
  end

end
