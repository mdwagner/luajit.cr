require "./spec_helper"

describe Luajit do
  it "works" do
    Luajit.run do |state|
      state.execute <<-LUA
      x = { name = "Michael" }
      LUA

      state.get_global("x")
      state.is_table?(-1).should be_true

      state.get_field(-1, "name")
      state.is_string?(-1).should be_true

      name = state.to_string(-1)
      name.should eq("Michael")
    end
  end

  it "works2" do
    Luajit.run do |state|
      Sprite.lua_def(state)

      state.execute <<-LUA
      local sprite = Sprite.new()
      sprite:move(5, 7)
      sprite:draw()
      LUA
    end
  end

  it "Crystal API in Lua", tags: "api" do
    Luajit.run do |state|
      state.new_table
      table_index = state.size
      io = IO::Memory.new

      state.tap do |_state|
        _state.push("gen_secret_key")
        _state.push do |_|
          io.puts Random::Secure.base64(32)
          0
        end
        _state.set_table(table_index)
      end

      state.set_global("Lucky")

      state.execute <<-LUA
      Lucky.gen_secret_key()
      LUA

      io.to_s.should_not be_empty
    end
  end
end
