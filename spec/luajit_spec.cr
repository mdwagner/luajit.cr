require "./spec_helper"

describe Luajit do
  it "works" do
    vm = Luajit::VM.new
    vm.execute <<-LUA
    x = { name = "Michael" }
    LUA

    vm.get_global("x")
    vm.is?(:table, -1).should be_true

    vm.get_field(-1, "name")
    vm.is?(:string, -1).should be_true

    name = vm.to_string(-1)
    name.should eq("Michael")
  end
end
