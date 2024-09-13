require "./spec_helper"
require "../src/wrappers/nil"

describe Luajit::Wrappers::NIL do
  it ".setup" do
    Luajit.run do |state|
      Luajit::Wrappers::NIL.setup(state)

      state.execute(<<-LUA).ok?.should be_true
      local x = NIL
      assert(type(x) == 'userdata')
      assert(x ~= nil)
      assert(tostring(x) == 'NIL')
      LUA
    end
  end

  it ".is_nil?" do
    Luajit.run do |state|
      Luajit::Wrappers::NIL.setup(state)

      state.execute("return NIL").ok?.should be_true
      Luajit::Wrappers::NIL.is_nil?(state, -1).should be_true

      state.execute("return nil").ok?.should be_true
      Luajit::Wrappers::NIL.is_nil?(state, -1).should be_false
    end
  end
end
