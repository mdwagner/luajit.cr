require "./spec_helper"

describe Luajit::LuaObject do
  describe "use cases" do
    it "works (defaults)" do
      Luajit.run do |state|
        Luajit.create_lua_object(state, SpecHelper::Sprite)

        state.execute(<<-'LUA').ok?.should be_true
        local sprite = Sprite.new()
        assert(sprite:x() == 1000)
        LUA
      end
    end

    it "works with different global name" do
      Luajit.run do |state|
        Luajit.create_lua_object(state, SpecHelper::Sprite2)

        state.execute(<<-'LUA').ok?.should be_true
        local sprite = SpriteGlob.new()
        assert(sprite:x() == 5000)
        LUA
      end
    end

    it "works with different metatable name" do
      Luajit.run do |state|
        Luajit.create_lua_object(state, SpecHelper::Sprite3)

        state.execute(<<-'LUA').ok?.should be_true
        local sprite = Sprite3.new()
        assert(sprite:x() == 3000)
        assert(getmetatable(sprite) == debug.getregistry()["SpriteMeta"])
        LUA
      end
    end

    it "works with different global name (full class name)" do
      Luajit.run do |state|
        Luajit.create_lua_object(state, SpecHelper::Sprite4)

        state.execute(<<-'LUA').ok?.should be_true
        local Sprite = _G["SpecHelper::Sprite4"]
        local sprite = Sprite.new()
        assert(sprite:x() == 8000)
        LUA
      end
    end
  end
end
