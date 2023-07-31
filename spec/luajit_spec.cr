require "./spec_helper"

describe Luajit do
  it "works" do
    l = Luajit::LuaState.new

    l.execute <<-LUA
    x = { name = "Michael" }
    LUA

    l.get_global("x")
    l.is?(:table, -1).should be_true

    l.get_field(-1, "name")
    l.is?(:string, -1).should be_true

    name = l.to_string(-1)
    name.should eq("Michael")
  end
end
