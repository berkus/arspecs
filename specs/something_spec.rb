require File.dirname(__FILE__) + "/../spec_helper"

#fixtures :somethings

context "A first object" do
  setup do
    @some = Something.find_by_id(1)
  end
  
  specify "is really a first object" do
    @some.text.should.equal "First"
  end
end

context "A second object", :somethings do
  setup do
    @second = Something.find_by_id(2)
  end
  
  specify "is really a second object" do
    @second.text.should.not.equal "First"
    @second.text.should.equal "Another"
  end
end
