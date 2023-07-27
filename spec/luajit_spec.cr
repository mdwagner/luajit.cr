require "./spec_helper"

describe Luajit do
  it "works" do
    vm = Luajit::VM.new
    l = vm.state
    num = 42

    l.push_function do |state|
      value = num + 36 # closure!
      state << value
      1
    end
    l.set_global("calculateNumber")

    l.execute <<-LUA
    x = { name = "Michael" }
    y = calculateNumber()
    LUA

    l.get_global("x")
    l.is?(:table, -1).should be_true

    l.get_field(-1, "name")
    l.is?(:string, -1).should be_true

    name = l.to_string(-1)
    name.should eq("Michael")

    l.get_global("y")
    l.is?(:number, -1).should be_true
  end
end
