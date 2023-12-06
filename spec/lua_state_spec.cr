require "./spec_helper"

describe Luajit::LuaState do
  describe "#less_than" do
    it "works" do
      Luajit.run do |state|
        state.push(1)
        state.push(2)
        state.less_than(-2, -1).should be_true
        state.less_than(-1, -2).should be_false

        SpecHelper.assert_stack_size!(state, 2)
      end
    end

    it "fails on nil values" do
      Luajit.run do |state|
        state.push(nil)
        state.push(nil)
        expect_raises(Luajit::LuaError, "lua_lessthan") do
          state.less_than(-2, -1)
        end

        SpecHelper.assert_stack_size!(state, 2)
      end
    end
  end

  describe "#eq" do
    it "works" do
      Luajit.run do |state|
        state.push(1)
        state.push(2)
        state.eq(-2, -1).should be_false

        state.push(2)
        state.eq(-2, -1).should be_true

        SpecHelper.assert_stack_size!(state, 3)
      end
    end
  end

  describe "#set_table" do
    it "works" do
      Luajit.run do |state|
        state.new_table
        state.push("message")
        state.push("hello world!")
        state.set_table(-3)

        state.push("message")
        state.get_table(-2)
        state.to_string(-1).should eq("hello world!")

        SpecHelper.assert_stack_size!(state, 2)
      end
    end
  end

  describe "#create_userdata" do
    it "works" do
      Luajit.run do |state|
        result = 999
        state.create_userdata(result)
        state.push(888)
        state.get_userdata(-2, typeof(result)).should eq(result)

        SpecHelper.assert_stack_size!(state, 2)
      end
    end
  end
end
