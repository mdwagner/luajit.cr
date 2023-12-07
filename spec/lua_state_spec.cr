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

  describe "#get_table" do
    it "works" do
      Luajit.run do |state|
        state.execute! <<-'LUA'
        x = { message = "hello world!" }
        LUA
        state.get_global("x")
        state.push("message")
        state.get_table(-2)
        state.to_string(-1).should eq("hello world!")

        SpecHelper.assert_stack_size!(state, 2)
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
        state.set_global("x")

        state.execute(<<-'LUA').ok?.should be_true
        assert(x.message == "hello world!")
        LUA

        SpecHelper.assert_stack_size!(state, 0)
      end
    end
  end

  describe "#new_userdata" do
    it "works with values" do
      Luajit.run do |state|
        state.new_metatable("result")
        state.pop(1)
        result = 1000
        box = Box(typeof(result)).box(result)
        state.new_userdata(box)
        state.attach_metatable(-1, "result").should be_true
        Box(typeof(result)).unbox(state.get_userdata(-1, "result")).should eq(result)

        SpecHelper.assert_stack_size!(state, 1)
      end
    end

    it "works with classes" do
      Luajit.run do |state|
        state.new_metatable("result")
        state.pop(1)
        result = SpecHelper::Sprite.new(100)
        box = Box(typeof(result)).box(result)
        state.new_userdata(box)
        state.attach_metatable(-1, "result").should be_true
        Box(typeof(result)).unbox(state.get_userdata(-1, "result")).should eq(result)

        SpecHelper.assert_stack_size!(state, 1)
      end
    end
  end

  describe "#attach_userdata" do
    it "fails if no metatable is created first" do
      Luajit.run do |state|
        state.new_table
        state.attach_metatable(-1, "result").should be_false

        SpecHelper.assert_stack_size!(state, 1)
      end
    end
  end

  describe "#to_h" do
    it "works" do
      Luajit.run do |state|
        state.execute! <<-'LUA'
        t = {
          number = 5,
          string = "hello world!",
          bool = true,
          fn = (function() end),
        }
        LUA
        state.get_global("t")
        hash = state.to_h(-1)

        hash["number"].as_f.should eq(5.0)
        hash["string"].as_s.should eq("hello world!")
        hash["bool"].as_bool.should be_true
        hash["fn"].as_ref.type.function?.should be_true

        SpecHelper.assert_stack_size!(state, 1)
      end
    end
  end

  describe "#to_a" do
    it "works" do
      Luajit.run do |state|
        state.execute! <<-'LUA'
        a = {1, 2, 3, 4, 5}
        LUA
        state.get_global("a")
        arr = state.to_a(-1)

        arr.map(&.as_f.to_i).should eq([1, 2, 3, 4, 5])

        SpecHelper.assert_stack_size!(state, 1)
      end
    end
  end

  describe "#push_fn_closure" do
    it "catches raised exceptions" do
      Luajit.run do |state|
        state.push_fn_closure do |s|
          raise "I did this!"
        end
        status = state.pcall(0, 0)
        status.runtime_error?.should be_true
        state.to_string(-1).should contain("I did this!")

        SpecHelper.assert_stack_size!(state, 1)
      end
    end
  end

  describe "#concat" do
    it "works" do
      Luajit.run do |state|
        state.push("hello")
        state.push(' ')
        state.push("world")
        state.push('!')
        state.concat(4)
        state.to_string(-1).should eq("hello world!")

        SpecHelper.assert_stack_size!(state, 1)
      end
    end

    it "pushes nothing if n == 1" do
      Luajit.run do |state|
        state.push("hello")
        state.push(' ')
        state.push("world")
        state.push('!')
        state.concat(1)
        state.to_string(-1).should eq("!")

        SpecHelper.assert_stack_size!(state, 4)
      end
    end

    it "pushes empty string if n == 0" do
      Luajit.run do |state|
        state.push("hello")
        state.push(' ')
        state.push("world")
        state.push('!')
        state.concat(0)
        state.to_string(-1).should eq("")

        SpecHelper.assert_stack_size!(state, 5)
      end
    end
  end
end
