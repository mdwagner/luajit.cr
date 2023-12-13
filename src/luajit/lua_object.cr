module Luajit
  abstract class LuaObject
    class_getter! global : String
    class_getter! metatable : String
    class_getter class_methods = {} of String => Luajit::LuaState::Function
    class_getter instance_methods = {} of String => Luajit::LuaState::Function

    # :nodoc:
    def self.default_global : String
      if self.name.includes?("::")
        self.name.split("::")[-1]
      else
        self.name
      end
    end

    def self.global_name(name : String) : Nil
      @@global = name
    end

    def self.metatable_name(name : String) : Nil
      @@metatable = name
    end

    def self.def_class_method(name : String, &block : Luajit::LuaState::Function)
      self.class_methods[name] = block
    end

    def self.def_instance_method(name : String, &block : Luajit::LuaState::Function)
      self.instance_methods[name] = block
    end
  end
end
