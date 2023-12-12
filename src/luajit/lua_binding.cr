module Luajit
  module LuaBinding
    macro included
      {% t = @type.stringify %}
      {% if t.includes?("::") %}
        @@__global = {{t.split("::")[-1]}}
        @@__metatable = {{t.split("::")[-1]}}
      {% else %}
        @@__global = {{t}}
        @@__metatable = {{t}}
      {% end %}
      @@__class_methods = {} of String => Luajit::LuaState::Function
      @@__instance_methods = {} of String => Luajit::LuaState::Function

      def self.global_name : String
        @@__global
      end

      def self.global_name(name : String) : Nil
        @@__global = name
      end

      def self.metatable_name : String
        @@__metatable
      end

      def self.metatable_name(name : String) : Nil
        @@__metatable = name
      end

      # :nodoc:
      def self.__class_methods : Hash(String, Luajit::LuaState::Function)
        @@__class_methods
      end

      def self.def_class_method(name : String, &block : Luajit::LuaState::Function)
        @@__class_methods[name] = block
      end

      # :nodoc:
      def self.__instance_methods : Hash(String, Luajit::LuaState::Function)
        @@__instance_methods
      end

      def self.def_instance_method(name : String, &block : Luajit::LuaState::Function)
        @@__instance_methods[name] = block
      end
    end

    # Generates bindings for *type*
    def self.generate_lua_binding(state : LuaState, type : T.class) : Nil forall T
      {% unless T <= Luajit::LuaBinding %}
        {% raise "'type' argument must include Luajit::LuaBinding" %}
      {% end %}

      state.new_table
      class_index = state.size
      state.push_value(class_index)
      state.set_global(type.global_name)

      state.new_metatable(type.metatable_name)
      instance_index = state.size

      type.__class_methods.each do |method_name, func|
        state.push(method_name)
        state.push(func)
        state.set_table(class_index)
      end

      type.__instance_methods.each do |method_name, func|
        state.push(method_name)
        case method_name
        when "__gc"
          state.push_fn_closure do |_s|
            _s.untrack(_s.get_userdata(-1, type.metatable_name))
            func.call(_s)
          end
        else
          state.push(func)
        end
        state.set_table(instance_index)
      end

      state.push_value(instance_index)
      state.set_field(instance_index, "__index")
    end

    # Converts *value* into full userdata with metatable *type* and returns
    # the userdata pointer
    def self.setup_userdata(state : LuaState, value : T, type : U.class) : Pointer(UInt64) forall T, U
      {% unless U <= Luajit::LuaBinding %}
        {% raise "'type' argument must include Luajit::LuaBinding" %}
      {% end %}

      box = Box(T).box(value)
      state.track(box)
      state.create_userdata(box, type.metatable_name)
    end

    # Gets value of userdata of *type*
    def self.userdata_value(state : LuaState, type : T.class) : T forall T
      {% unless T <= Luajit::LuaBinding %}
        {% raise "'type' argument must include Luajit::LuaBinding" %}
      {% end %}

      ud_ptr = state.get_userdata(1, type.metatable_name)
      Box(T).unbox(ud_ptr)
    end
  end
end
