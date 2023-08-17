module Luajit
  struct LuaState
    alias CFunction = LibLuaJIT::CFunction
    alias Function = LuaState -> Int32
    alias Loader = LuaState, Pointer(UInt64) -> String?
    alias Unloader = LuaState, Pointer(Void), UInt64 -> Int32

    enum ThreadStatus
      Main
      Coroutine
    end

    @ptr : Pointer(LibLuaJIT::State)

    def self.metatable_name(name : String) : String
      "luajit_cr::#{name}"
    end

    def initialize(@ptr)
    end

    def to_unsafe
      @ptr
    end

    # Similar to `lua_close`
    def close : Nil
      LibLuaJIT.lua_close(self)
    end

    # Returns the version number of this core
    def version : Float64
      LibLuaJIT.lua_version(self).value
    end

    # Similar to `luaopen_*`
    #
    # `LuaLibrary::All` is similar to `luaL_openlibs`
    def open_library(type : LuaLibrary) : Nil
      {% begin %}
      case type
      {% for t in LuaLibrary.constants.map(&.underscore) %}
        {% if t == "all" %}
        in .all?
          LibLuaJIT.luaL_openlibs(self)
        {% else %}
        in .{{t.id}}?
          LibLuaJIT.luaopen_{{t.id}}(self)
        {% end %}
      {% end %}
      end
      {% end %}
    end

    # Similar to `lua_gc`
    def gc : LuaGC
      LuaGC.new(to_unsafe)
    end

    # Similar to `lua_atpanic`
    def at_panic(&cb : CFunction) : CFunction
      LibLuaJIT.lua_atpanic(self, cb)
    end

    # Similar to `lua_concat`
    def concat(n : Int32) : Nil
      LibLuaJIT.lua_concat(self, n)
    end

    # Similar to `lua_gettop`
    def size : Int32
      LibLuaJIT.lua_gettop(self)
    end

    # Similar to `lua_settop`
    def set_top(index : Int32) : Nil
      LibLuaJIT.lua_settop(self, index)
    end

    # Similar to `lua_pop`
    def pop(n : Int32) : Nil
      LibxLuaJIT.lua_pop(self, n)
    end

    # Similar to `lua_getfield`
    def get_field(index : Int32, name : String)
      LibLuaJIT.lua_getfield(self, index, name)
    end

    # Similar to `lua_setfield`
    def set_field(index : Int32, k : String) : Nil
      LibLuaJIT.lua_setfield(self, index, k)
    end

    # Similar to `lua_getglobal`
    def get_global(name : String)
      LibxLuaJIT.lua_getglobal(self, name)
    end

    # Similar to `lua_setglobal`
    def set_global(name : String) : Nil
      LibxLuaJIT.lua_setglobal(self, name)
    end

    # Similar to `lua_getmetatable`
    def get_metatable(index : Int32) : Int32
      LibLuaJIT.lua_getmetatable(self, index)
    end

    # Similar to `luaL_getmetatable`
    def get_metatable(tname : String) : Nil
      LibxLuaJIT.luaL_getmetatable(self, tname)
    end

    # Similar to `lua_setmetatable`
    def set_metatable(index : Int32) : Int32
      LibLuaJIT.lua_setmetatable(self, index)
    end

    # Similar to `lua_gettable`
    def get_table(index : Int32) : Nil
      LibLuaJIT.lua_gettable(self, index)
    end

    # Similar to `lua_settable`
    def set_table(index : Int32) : Nil
      LibLuaJIT.lua_settable(self, index)
    end

    # Similar to `lua_createtable`
    def create_table(narr : Int32, nrec : Int32) : Nil
      LibLuaJIT.lua_createtable(self, narr, nrec)
    end

    # Similar to `luaL_newmetatable`
    def new_metatable(tname : String) : Int32
      LibLuaJIT.luaL_newmetatable(self, tname)
    end

    # Similar to `luaL_getmetafield`
    def get_metafield(obj : Int32, e : String) : Int32
      LibLuaJIT.luaL_getmetafield(self, obj, e)
    end

    # Similar to `lua_toboolean`
    def to_boolean(index : Int32) : Bool
      LibLuaJIT.lua_toboolean(self, index) == true.to_unsafe
    end

    # Same as `LuaState#to_i32`
    def to_i(index : Int32) : Int32
      to_i32(index)
    end

    # Returns `LuaState#to_i64` converted to `Int32`
    def to_i32(index : Int32) : Int32
      to_i64(index).to_i
    end

    # Similar to `lua_tointeger`
    def to_i64(index : Int32) : Int64
      LibLuaJIT.lua_tointeger(self, index)
    end

    # Similar to `lua_tolstring`
    def to_string(index : Int32, size : UInt64) : String
      String.new(LibLuaJIT.lua_tolstring(self, index, pointerof(size)))
    end

    # Similar to `lua_tostring`
    def to_string(index : Int32) : String
      LibxLuaJIT.lua_tostring(self, index)
    end

    # Same as `LuaState#to_f64`
    def to_f(index : Int32) : Float64
      to_f64(index)
    end

    # Returns `LuaState#to_f64` converted to `Float32`
    def to_f32(index : Int32) : Float32
      to_f64(index).to_f32
    end

    # Similar to `lua_tonumber`
    def to_f64(index : Int32) : Float64
      LibLuaJIT.lua_tonumber(self, index)
    end

    # Similar to `lua_touserdata`
    def to_userdata(index : Int32) : Pointer(Void)
      LibLuaJIT.lua_touserdata(self, index)
    end

    # Similar to `lua_tocfunction`
    def to_c_function?(index : Int32) : CFunction?
      proc = LibLuaJIT.lua_tocfunction(self, index)
      if proc.pointer
        proc
      end
    end

    # Same as `LuaState#to_c_function?`, but will raise on nil
    def to_c_function(index : Int32) : CFunction
      to_c_function?(index).not_nil!
    end

    # Similar to `lua_tothread`
    def to_thread?(index : Int32) : LuaState?
      if ptr = LibLuaJIT.lua_tothread(self, index)
        LuaState.new(ptr)
      end
    end

    # Same as `LuaState#to_thread?`, but will raise on nil
    def to_thread(index : Int32) : LuaState
      to_thread?(index).not_nil!
    end

    # Similar to `lua_pushboolean`
    def push(x : Bool) : self
      LibLuaJIT.lua_pushboolean(self, x)
      self
    end

    # Similar to `lua_pushinteger`
    def push(x : Int64) : self
      LibLuaJIT.lua_pushinteger(self, x)
      self
    end

    # Same as `LuaState#push`, but converts _x_ value to `Int64` first
    def push(x : Int32) : self
      push(x.to_i64)
    end

    # Similar to `lua_pushlightuserdata`
    def push(x : Pointer(Void)) : self
      LibLuaJIT.lua_pushlightuserdata(self, x)
      self
    end

    # Similar to `lua_pushnil`
    def push(_x : Nil) : self
      LibLuaJIT.lua_pushnil(self)
      self
    end

    # Similar to `lua_pushnumber`
    def push(x : Float64) : self
      LibLuaJIT.lua_pushnumber(self, x)
      self
    end

    # Similar to `lua_pushstring`
    def push(x : String) : self
      LibLuaJIT.lua_pushstring(self, x)
      self
    end

    # Same as `LuaState#push`, but converts _x_ value to `String` first
    def push(x : Char) : self
      push(x.to_s)
    end

    # Same as `LuaState#push`, but converts _x_ value to `String` first
    def push(x : Symbol) : self
      push(x.to_s)
    end

    # Creates an index-based Lua table from _x_
    def push(x : Array) : self
      create_table(x.size, 0)
      x.each_with_index do |item, index|
        push(index + 1)
        push(item)
        set_table(-3)
      end
      self
    end

    # Creates an key-value based Lua table from _x_
    def push(x : Hash) : self
      create_table(0, x.size)
      x.each do |key, value|
        push(key)
        push(value)
        set_table(-3)
      end
      self
    end

    # Similar to `lua_pushcclosure`
    def push(&block : Function) : self
      box = Box(typeof(block)).box(block)
      track(box)
      proc = CFunction.new do |l|
        state = LuaState.new(l)
        ud = state.to_userdata(state.upvalue_at(1))
        Box(typeof(block)).unbox(ud).call(state)
      end
      push(box)
      LibLuaJIT.lua_pushcclosure(self, proc, 1)
      self
    end

    # Similar to `lua_pushthread`
    def push_thread(thread : LuaState) : ThreadStatus
      if LibLuaJIT.lua_pushthread(thread) == 1
        ThreadStatus::Main
      else
        ThreadStatus::Coroutine
      end
    end

    # Similar to `lua_pushvalue`
    def push_value(index : Int32) : Nil
      LibLuaJIT.lua_pushvalue(self, index)
    end

    # Similar to `lua_pcall`
    def pcall(nargs : Int32, nresults : Int32, errfunc : Int32 = 0) : Int32
      LibLuaJIT.lua_pcall(self, nargs, nresults, errfunc)
    end

    # Similar to `lua_cpcall`
    def c_pcall(&block : Function) : LuaStatus
      box = Box(typeof(block)).box(block)
      proc = CFunction.new do |l|
        state = LuaState.new(l)
        ud = state.to_userdata(-1)
        state.pop(-1)
        Box(typeof(block)).unbox(ud).call(state)
      end
      LuaStatus.new(LibLuaJIT.lua_cpcall(self, proc, box))
    end

    # Similar to `lua_isboolean`
    def is_bool?(index : Int32) : Bool
      LibxLuaJIT.lua_isboolean(self, index)
    end

    # Similar to `lua_isnumber`
    def is_number?(index : Int32) : Bool
      LibLuaJIT.lua_isnumber(self, index) == true.to_unsafe
    end

    # Similar to `lua_isstring`
    def is_string?(index : Int32) : Bool
      LibLuaJIT.lua_isstring(self, index) == true.to_unsafe
    end

    # Similar to `lua_isfunction`
    def is_function?(index : Int32) : Bool
      LibxLuaJIT.lua_isfunction(self, index)
    end

    # Similar to `lua_iscfunction`
    def is_c_function?(index : Int32) : Bool
      LibLuaJIT.lua_iscfunction(self, index) == true.to_unsafe
    end

    # Similar to `lua_isuserdata`
    def is_userdata?(index : Int32) : Bool
      LibLuaJIT.lua_isuserdata(self, index) == true.to_unsafe
    end

    # Similar to `lua_islightuserdata`
    def is_light_userdata?(index : Int32) : Bool
      LibxLuaJIT.lua_islightuserdata(self, index)
    end

    # Similar to `lua_isthread`
    def is_thread?(index : Int32) : Bool
      LibxLuaJIT.lua_isthread(self, index)
    end

    # Similar to `lua_istable`
    def is_table?(index : Int32) : Bool
      LibxLuaJIT.lua_istable(self, index)
    end

    # Similar to `lua_isnil`
    def is_nil?(index : Int32) : Bool
      LibxLuaJIT.lua_isnil(self, index)
    end

    # Similar to `lua_isnone`
    def is_none?(index : Int32) : Bool
      LibxLuaJIT.lua_isnone(self, index)
    end

    # Similar to `lua_isnoneornil`
    def is_none_or_nil?(index : Int32) : Bool
      LibxLuaJIT.lua_isnoneornil(self, index)
    end

    # Similar to `lua_type`
    def get_type(index : Int32) : LuaType
      LuaType.new(LibLuaJIT.lua_type(self, index))
    end

    # Similar to `lua_typename`
    def type_name(lua_type : LuaType) : String
      String.new(LibLuaJIT.lua_typename(self, lua_type.value))
    end

    # Similar to `luaL_typename`
    #
    # Can also be created from a combination of `#get_type` and `#type_name`
    def type_name_at(index : Int32) : String
      String.new(LibLuaJIT.luaL_typename(self, index))
    end

    # Similar to `lua_lessthan`
    def less_than(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_lessthan(self, index1, index2) == true.to_unsafe
    end

    # Similar to `lua_insert`
    def insert(index : Int32) : Nil
      LibLuaJIT.lua_insert(self, index)
    end

    # Similar to `lua_remove`
    def remove(index : Int32) : Nil
      LibLuaJIT.lua_remove(self, index)
    end

    # Similar to `lua_replace`
    def replace(index : Int32) : Nil
      LibLuaJIT.lua_replace(self, index)
    end

    # Similar to `lua_resume`
    def resume(nargs : Int32) : Int32
      LibLuaJIT.lua_resume(self, nargs)
    end

    # Similar to `lua_equal`
    def eq(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_equal(self, index1, index2) == true.to_unsafe
    end

    # Similar to `lua_next`
    def next(index : Int32) : Bool
      LibLuaJIT.lua_next(self, index) == true.to_unsafe
    end

    # Similar to `lua_objlen`
    def size_at(index : Int32) : UInt64
      LibLuaJIT.lua_objlen(self, index)
    end

    # Similar to `lua_rawequal`
    def raw_eq(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_rawequal(self, index1, index2) == true.to_unsafe
    end

    # Similar to `lua_rawget`
    def raw_get(index : Int32) : Nil
      LibLuaJIT.lua_rawget(self, index)
    end

    # Similar to `lua_rawgeti`
    def raw_get_index(index : Int32, n : Int32) : Nil
      LibLuaJIT.lua_rawgeti(self, index, n)
    end

    # Similar to `lua_rawset`
    def raw_set(index : Int32) : Nil
      LibLuaJIT.lua_rawset(self, index)
    end

    # Similar to `lua_rawseti`
    def raw_set_index(index : Int32, n : Int32) : Nil
      LibLuaJIT.lua_rawseti(self, index, n)
    end

    # Similar to `lua_upvalueindex`
    def upvalue_at(index : Int32) : Int32
      LibxLuaJIT.lua_upvalueindex(index)
    end

    # Similar to `lua_status`
    def status(state : LuaState) : LuaStatus
      LuaStatus.new(LibLuaJIT.lua_status(state))
    end

    # Returns LuaStatus on self
    def status : LuaStatus
      status(self)
    end

    # Similar to `luaL_callmeta`
    def call_metamethod(object_index : Int32, method_name : String) : Bool
      LibLuaJIT.luaL_callmeta(self, object_index, method_name) == true.to_unsafe
    end

    # Similar to `lua_newtable`
    def new_table : Nil
      LibxLuaJIT.lua_newtable(self)
    end

    # Similar to `lua_newthread`
    def new_thread : LuaState
      LuaState.new(LibLuaJIT.lua_newthread(self))
    end

    # Similar to `lua_register`
    def register_global(name : String, &block : Function) : Nil
      push(&block)
      set_global(name)
    end

    # Similar to `lua_xmove`
    def xmove(from : LuaState, to : LuaState, n : Int32) : Nil
      LibLuaJIT.lua_xmove(from, to, n)
    end

    # Similar to `lua_yield`
    def coroutine_yield(nresults : Int32) : Int32
      LibLuaJIT.lua_yield(from, to, n)
    end

    # Similar to `lua_load`
    def load(chunk_name : String, &block : Loader) : LuaStatus
      box = Box(typeof(block)).box(block)
      proc = LibLuaJIT::Reader.new do |l, data, size|
        state = LuaState.new(l)
        Box(typeof(block)).unbox(data).call(state, size)
      end
      result = LuaStatus.new(LibLuaJIT.lua_load(self, proc, box, chunk_name))
      case result
      when .syntax_error?
        raise LuaSyntaxError.new
      when .memory_error?
        raise LuaMemoryError.new
      end
      result
    end

    # Similar to `lua_dump`
    def dump(&block : Unloader) : Int32
      box = Box(typeof(block)).box(block)
      proc = LibLuaJIT::Writer.new do |l, ptr, size, ud|
        state = LuaState.new(l)
        Box(typeof(block)).unbox(ud).call(state, ptr, size)
      end
      LibLuaJIT.lua_dump(self, proc, box)
    end

    # Similar to `luaL_dostring`
    def execute(code : String) : Nil
      case LuaStatus.new(LibxLuaJIT.luaL_dostring(self, code))
      when .runtime_error?
        raise LuaRuntimeError.new
      when .memory_error?
        raise LuaMemoryError.new
      when .handler_error?
        raise LuaHandlerError.new
      end
    end

    # Similar to `luaL_dofile`
    def execute(path : Path) : Nil
      case LuaStatus.new(LibxLuaJIT.luaL_dofile(self, path))
      when .runtime_error?
        raise LuaRuntimeError.new
      when .memory_error?
        raise LuaMemoryError.new
      when .handler_error?
        raise LuaHandlerError.new
      end
    end

    # Similar to `lua_error`
    def raise_error : Nil
      LibLuaJIT.lua_error(self)
    end

    # Similar to `luaL_error`
    def raise_error(reason : String) : Nil
      LibLuaJIT.luaL_error(self, reason)
    end

    # Similar to `luaL_argerror`
    def raise_arg(pos : Int32, reason : String) : Nil
      LibLuaJIT.luaL_argerror(self, pos, reason)
    end

    # Similar to `luaL_typerror`
    def raise_type(pos : Int32, type : String) : Nil
      LibLuaJIT.luaL_typerror(self, pos, type)
    end

    def assert_args_lt(num_args : Int32, msg : String = "not enough arguments") : Nil
      if size < num_args
        raise_error(msg)
      end
    end

    def assert_args_gt(num_args : Int32, msg : String = "too many arguments") : Nil
      if size > num_args
        raise_error(msg)
      end
    end

    def assert_args_eq(num_args : Int32, msg : String = "unexpected number of arguments") : Nil
      unless size == num_args
        raise_error(msg)
      end
    end

    def assert_none?(index : Int32) : Nil
      unless is_none?(index)
        raise_type(index, type_name(:none))
      end
    end

    def assert_nil?(index : Int32) : Nil
      unless is_nil?(index)
        raise_type(index, type_name(:nil))
      end
    end

    def assert_bool?(index : Int32) : Nil
      unless is_bool?(index)
        raise_type(index, type_name(:bool))
      end
    end

    def assert_light_userdata?(index : Int32) : Nil
      unless is_light_userdata?(index)
        raise_type(index, type_name(:light_userdata))
      end
    end

    def assert_number?(index : Int32) : Nil
      unless is_number?(index)
        raise_type(index, type_name(:number))
      end
    end

    def assert_string?(index : Int32) : Nil
      unless is_string?(index)
        raise_type(index, type_name(:string))
      end
    end

    def assert_table?(index : Int32) : Nil
      unless is_table?(index)
        raise_type(index, type_name(:table))
      end
    end

    def assert_function?(index : Int32) : Nil
      unless is_function?(index)
        raise_type(index, type_name(:function))
      end
    end

    def assert_userdata?(index : Int32) : Nil
      unless is_userdata?(index)
        raise_type(index, type_name(:userdata))
      end
    end

    def assert_thread?(index : Int32) : Nil
      unless is_thread?(index)
        raise_type(index, type_name(:thread))
      end
    end

    #######################################################

    # Same as `Luajit.add_trackable`
    def track(ptr : Pointer(Void)) : Nil
      Luajit.add_trackable(ptr)
    end

    # Same as `Luajit.remove_trackable`
    def untrack(ref : Reference) : Nil
      Luajit.remove_trackable(ref)
    end

    def create_userdata(value, name : String) : Nil
      # create userdata pointer
      ud_ptr = LibLuaJIT.lua_newuserdata(self, sizeof(typeof(value)))
      # assign value to userdata pointer
      ud_ptr.as(Pointer(typeof(value))).value = value
      # store index of userdata
      ud_index = size
      # get metatable name
      meta_name = LuaState.metatable_name(name)
      # user metatable name to add to stack
      get_metatable(meta_name)
      # set metatable to userdata
      set_metatable(ud_index)
    end

    def create_userdata(ref : Reference, name : String) : Nil
      track(Box.box(ref))
      # create userdata pointer
      ud_ptr = LibLuaJIT.lua_newuserdata(self, sizeof(typeof(ref)))
      # assign ref to userdata pointer
      ud_ptr.as(Pointer(typeof(ref))).value = ref
      # store index of userdata
      ud_index = size
      # get metatable name
      meta_name = LuaState.metatable_name(name)
      # user metatable name to add to stack
      get_metatable(meta_name)
      # set metatable to userdata
      set_metatable(ud_index)
    end

    def destroy_userdata(ref : Reference) : Nil
      untrack(ref)
    end

    def get_userdata(_type : U.class, index : Int32) : U forall U
      to_userdata(index).as(Pointer(U)).value
    end
  end
end
