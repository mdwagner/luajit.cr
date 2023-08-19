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
end
