require File.dirname(__FILE__) + "/../spec_helper"

puts "Start"

fixtures :somethings

fixture_context "A first object" do
  setup do
    puts "setup1"
    @some = Something.find_by_id(1)
  end
  
  specify "is really a first object" do
    puts "specify1"
    @some.text.should.equal "First"
  end
end

fixture_context "A second object", :somethings do
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
