require "./spec_helper"
require "../src/wrappers/string"

describe Luajit::Wrappers::String do
  it ".split" do
    Luajit.run do |state|
      Luajit::Wrappers::String.setup(state)
      state.pop(2)

      state.execute(<<-'LUA').ok?.should be_true
      return String.split("foo,bar,baz", ",")
      LUA

      arr = state.to_a(-1)
      arr.map(&.as_s).should eq(["foo", "bar", "baz"])

      SpecHelper.assert_stack_size!(state, 1)
    end
  end
end
