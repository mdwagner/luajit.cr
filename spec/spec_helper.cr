require "spec"
require "../src/luajit"

module SpecHelper
  macro assert_stack_size!(state, size)
    {{state}}.size.should eq({{size}})
  end

  class Sprite < Luajit::LuaObject
    def_class_method "new" do |state|
      _self = new(1000)
      Luajit.setup_userdata(state, _self, self)
      1
    end

    def_instance_method "x" do |state|
      _self = Luajit.userdata_value(state, self, 1)
      state.push(_self.x)
      1
    end

    property x : Int32

    def initialize(@x)
    end
  end

  class Sprite2 < Luajit::LuaObject
    global_name "SpriteGlob"

    def_class_method "new" do |state|
      _self = new(5000)
      Luajit.setup_userdata(state, _self, self)
      1
    end

    def_instance_method "x" do |state|
      _self = Luajit.userdata_value(state, self, 1)
      state.push(_self.x)
      1
    end

    property x : Int32

    def initialize(@x)
    end
  end

  class Sprite3 < Luajit::LuaObject
    metatable_name "SpriteMeta"

    def_class_method "new" do |state|
      _self = new(3000)
      Luajit.setup_userdata(state, _self, self)
      1
    end

    def_instance_method "x" do |state|
      _self = Luajit.userdata_value(state, self, 1)
      state.push(_self.x)
      1
    end

    property x : Int32

    def initialize(@x)
    end
  end

  class Sprite4 < Luajit::LuaObject
    global_name(self.name)

    def_class_method "new" do |state|
      _self = new(8000)
      Luajit.setup_userdata(state, _self, self)
      1
    end

    def_instance_method "x" do |state|
      _self = Luajit.userdata_value(state, self, 1)
      state.push(_self.x)
      1
    end

    property x : Int32

    def initialize(@x)
    end
  end
end
