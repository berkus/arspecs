require 'spec'
require 'active_record/fixtures'

class FixturesHandler
  cattr_accessor :fixture_path
  cattr_accessor :fixture_table_names
  cattr_accessor :use_transactional_fixtures
  
  self.fixture_path = RAILS_ROOT + "/test/fixtures/"
  self.fixture_table_names = []
  self.use_transactional_fixtures = false
	    
  def initialize(table_names)
    fixtures(table_names)
  end

  def self.fixtures(*table_names)
    table_names = table_names.flatten.map { |n| n.to_s }
    self.fixture_table_names |= table_names
    require_fixture_classes(table_names)
  end
					      
  def self.require_fixture_classes(table_names)
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

  def use_transactional_fixtures?
    self.use_transactional_fixtures
  end

  def load_fixtures
    @loaded_fixtures = {}
    fixtures = Fixtures.create_fixtures(@@fixture_path, @@fixture_table_names)
    unless fixtures.nil?
      if fixtures.instance_of?(Fixtures)
        @loaded_fixtures[fixtures.table_name] = fixtures
      else
        fixtures.each { |f| @loaded_fixtures[f.table_name] = f }
      end
    end
  
    if use_transactional_fixtures?
      ActiveRecord::Base.lock_mutex
      ActiveRecord::Base.connection.begin_db_transaction
    end
  end

  def teardown_fixtures
    # Rollback changes.
    if use_transactional_fixtures?
      ActiveRecord::Base.connection.rollback_db_transaction
      ActiveRecord::Base.unlock_mutex
    end
    ActiveRecord::Base.clear_connection_cache!
  end
end

module Kernel
  def fixtures(*table_names)
    FixturesHandler.fixtures(table_names)
  end

  def context(name, *table_names, &block)
    @fixtures = FixturesHandler.new(table_names)
    @fixtures.load_fixtures
    Spec::Runner::Context.new(name, &block)
    @fixtures.teardown_fixtures
  end
end
