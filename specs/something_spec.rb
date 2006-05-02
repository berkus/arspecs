require File.dirname(__FILE__) + "/../spec_helper"

puts "Start"

fixtures :somethings
use_transactional_fixtures true

context "A first object" do
  setup do
    puts "context_setup"
    @some = Something.find_by_id(1)
    puts @some.inspect
  end
  
  specify "is really a first object" do
    puts "specify"
    puts @some.inspect
    @some.text.should.equal "First"
  end
end

context "A second object", :somethings do
  setup do
    puts "setup2"
    @second = Something.find_by_id(2)
  end
  
  specify "is really a second object" do
    puts "specify2"
    @second.text.should.not.equal "First"
    @second.text.should.equal "Another"
  end
end

puts "End"
