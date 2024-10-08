require "./luajit/version"
require "./luajit/lib_luajit"
require "./luajit/lua_type"
require "./luajit/lua_ref"
require "./luajit/lua_any"
require "./luajit/*"

module Luajit
  # :nodoc:
  module Wrappers
  end

  # Same as `LuaState.create`
  def self.new(defaults : Bool = false) : LuaState
    LuaState.create.tap do |state|
      state.open_library(:all) if defaults
    end
  end

  # Same as `.new`, but also opens all Lua libraries
  @[Deprecated("Use `.new(defaults: true)` instead")]
  def self.new_with_defaults : LuaState
    new(defaults: true)
  end

  # Same as `LuaState.destroy`
  def self.close(state : LuaState) : Nil
    LuaState.destroy(state)
  end

  # Yields a new `LuaState` and closes it at end of block
  def self.run(defaults : Bool = true, & : LuaState ->) : Nil
    state = new(defaults: defaults)
    begin
      yield state
    ensure
      close(state)
    end
  end

  # Creates a Lua object for *type*
  #
  # NOTE: Will mutate *type* global name or metatable name unless set
  def self.create_lua_object(state : LuaState, type : T.class) : Nil forall T
    {% unless T < Luajit::LuaObject %}
      {% raise "'type' argument must be a Luajit::LuaObject" %}
    {% end %}

    unless type.global?
      type.global_name(type.default_global)
    end
    state.register(type.global)
    class_table_index = state.size

    unless type.metatable?
      type.metatable_name(type.global)
    end
    state.new_metatable(type.metatable)
    instance_table_index = state.size

    type.class_methods.each do |name, proc|
      state.push(name)
      state.push(proc)
      state.set_table(class_table_index)
    end

    state.push("__gc")
    state.push_fn_closure do |_state|
      if _state.is_userdata?(-1)
        _state.untrack(_state.get_userdata(-1, type.metatable))
      end
      if proc = type.instance_methods["__gc"]?
        proc.call(_state)
      else
        0
      end
    end
    state.set_table(instance_table_index)

    type.instance_methods.reject("__gc").each do |name, proc|
      state.push(name)
      state.push(proc)
      state.set_table(instance_table_index)
    end

    unless type.instance_methods["__index"]?
      state.push_value(instance_table_index)
      state.set_field(instance_table_index, "__index")
    end
  end

  # Converts *value* into full userdata with metatable *type*
  def self.setup_userdata(state : LuaState, value : T, type : U.class) : Nil forall T, U
    {% unless U < Luajit::LuaObject %}
      {% raise "'type' argument must be a Luajit::LuaObject" %}
    {% end %}
    box = Box(T).box(value)
    state.track(box)
    state.create_userdata(box, type.metatable)
  end

  # Gets value of userdata of *type* at *index*
  def self.userdata_value(state : LuaState, type : T.class, index : Int32) : T forall T
    {% unless T < Luajit::LuaObject %}
      {% raise "'type' argument must be a Luajit::LuaObject" %}
    {% end %}
    ud_ptr = state.get_userdata(index, type.metatable)
    Box(T).unbox(ud_ptr)
  end
end
