require "./spec_helper"

describe Luajit::LuaState do
  context "#less_than" do
    it "performs operation successfully" do
      Luajit.once do |state|
        state.push(1)
        state.push(2)
        state.less_than(-2, -1).should be_true
        state.less_than(-1, -2).should be_false

        state.size.should eq(2)
      end
    end
    it "fails to perform operation" do
      Luajit.once do |state|
        state.push(nil)
        state.push(nil)
        expect_raises(Luajit::LuaProtectedError, "lua_lessthan") do
          state.less_than(-2, -1)
        end

        state.size.should eq(2)
      end
    end
  end

  context "#eq" do
    it "performs operation successfully" do
      Luajit.once do |state|
        state.push(1)
        state.push(2)
        state.eq(-2, -1).should be_false

        state.push(2)
        state.eq(-2, -1).should be_true

        state.size.should eq(3)
      end
    end
  end

  context "table operations" do
    it "perform successfully" do
      Luajit.once do |state|
        state.new_table
        state.push("message")
        state.push("hello world!")
        state.set_table(-3)

        state.push("message")
        state.get_table(-2)
        state.to_string(-1).should eq("hello world!")

        state.size.should eq(2)
      end
    end
  end

  context "#register_library" do
    it "performs successfully" do
      Luajit.once do |state|
        state.register_library("Crystal", [
          Luajit::LuaReg.new("puts") { |l|
            s = Luajit::LuaState.new(l)
            if s.is_string?(-1)
              puts s.to_string(-1)
            end
            0
          }
        ])

        state.size.should eq(1)
      end
    end
  end

  context "#register_table_functions" do
    it "performs successfully" do
      Luajit.once do |state|
        state.new_table
        state.register_table_functions([
          Luajit::LuaReg.new("puts") { |l|
            s = Luajit::LuaState.new(l)
            if s.is_string?(-1)
              puts s.to_string(-1)
            end
            0
          }
        ])

        state.size.should eq(1)
      end
    end
  end
end
