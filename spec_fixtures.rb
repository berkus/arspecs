require 'spec'
require 'active_record/fixtures'

class Spec::Runner::Specification
  cattr_accessor :fixture_path
  cattr_accessor :fixture_table_names
  cattr_accessor :use_transactional_fixtures

  @@fixture_path = RAILS_ROOT + "/test/fixtures/"
  @@fixture_table_names = []
  @@use_transactional_fixtures = false
  @@already_loaded_fixtures = {}
      	    
  def self.fixtures(*table_names)
    puts "fixtures(#{table_names.inspect})"
    table_names = table_names.flatten.map { |n| n.to_s }
    @@fixture_table_names |= table_names
    require_fixture_classes(table_names)
  end

  def use_transactional_fixtures?
    self.use_transactional_fixtures
  end

  alias_method :old_run, :run
  
  def run(reporter=nil, setup_block=nil, teardown_block=nil)
    setup_fixtures
    old_run(reporter, setup_block, teardown_block)
    teardown_fixtures
  end

  private

  def setup_fixtures
    puts "setup_fixtures"
    # Load fixtures once and begin transaction.
    if use_transactional_fixtures?
      if @@already_loaded_fixtures[self.class]
        @loaded_fixtures = @@already_loaded_fixtures[self.class]
      else
        load_fixtures
        @@already_loaded_fixtures[self.class] = @loaded_fixtures
      end

      ActiveRecord::Base.lock_mutex
      ActiveRecord::Base.connection.begin_db_transaction
      puts "transaction begin"

    # Load fixtures for every test.
    else
      @@already_loaded_fixtures[self.class] = nil
      load_fixtures
    end
    
    raise "No fixtures loaded!" if @loaded_fixtures.empty?
  end

  def teardown_fixtures
    puts "teardown_fixtures"
    # Rollback changes.
    if use_transactional_fixtures?
      ActiveRecord::Base.connection.rollback_db_transaction
      ActiveRecord::Base.unlock_mutex
      puts "transaction end"
    end
    ActiveRecord::Base.clear_connection_cache!
  end

  def load_fixtures
    puts "load_fixtures"
    @loaded_fixtures = {}
    fixtures = Fixtures.create_fixtures(@@fixture_path, @@fixture_table_names)
    unless fixtures.nil?
      if fixtures.instance_of?(Fixtures)
        @loaded_fixtures[fixtures.table_name] = fixtures
      else
        fixtures.each { |f| @loaded_fixtures[f.table_name] = f }
      end
    end
  end

  def self.require_fixture_classes(table_names)
    puts "require_fixture_classes(#{table_names.inspect})"
    table_names.each do |table_name| 
      file_name = table_name.to_s
      file_name = file_name.singularize if ActiveRecord::Base.pluralize_table_names
      begin
        require file_name
      rescue LoadError
        # Let's hope the developer has included it himself
      end
    end
  end
end

module Kernel
  def fixtures(*table_names)
    Spec::Runner::Specification.fixtures(table_names)
  end
  
  def use_transactional_fixtures(enable)
    Spec::Runner::Specification.use_transactional_fixtures = enable
  end

  def context(name, *table_names, &block)
    puts "context(#{name}, #{table_names.inspect})"
    fixtures(table_names) if table_names.size > 0
    Spec::Runner::Context.new(name, &block)
  end
end
