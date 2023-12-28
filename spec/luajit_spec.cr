require "./spec_helper"

describe Luajit do
  describe "global nil" do
    it ".setup_global_nil" do
      Luajit.run do |state|
        Luajit.setup_global_nil(state)

        state.execute(<<-'LUA').ok?.should be_true
        local x = NIL
        assert(type(x) == 'userdata')
        assert(x ~= nil)
        assert(tostring(x) == 'NIL')
        LUA
      end
    end

    it ".is_global_nil?" do
      Luajit.run do |state|
        Luajit.setup_global_nil(state)

        state.execute(<<-'LUA').ok?.should be_true
        return NIL
        LUA
        Luajit.is_global_nil?(state, -1).should be_true

        state.execute(<<-'LUA').ok?.should be_true
        return nil
        LUA
        Luajit.is_global_nil?(state, -1).should be_false
      end
    end
  end
end
