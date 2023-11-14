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

    # Returns the pointer address of _state_
    #
    # :nodoc:
    def self.pointer_address(state : LuaState) : String
      state.to_unsafe.address.to_s
    end

    # Sets the _state_ pointer address inside it's own registry
    #
    # Used with `#get_registry_address` for tracking whether a LuaState
    # instance or thread is part of a parent LuaState instance
    #
    # :nodoc:
    def self.set_registry_address(state : LuaState) : Nil
      state.push(pointer_address(state))
      state.set_field(LibLuaJIT::LUA_REGISTRYINDEX, LuaState.metatable_name("__LuaState__"))
    end

    def initialize(@ptr)
    end

    def to_unsafe
      @ptr
    end

    # Returns the LuaState pointer address inside the registry
    #
    # Works across the main thread and child threads
    #
    # :nodoc:
    def get_registry_address : String
      get_field(LibLuaJIT::LUA_REGISTRYINDEX, LuaState.metatable_name("__LuaState__"))
      to_string(-1).tap do
        remove(-1)
      end
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
    def get_global(name : String) : Nil
      unsafe_push_cfunction do |l|
        state = LuaState.new(l)
        state.unsafe_get_global(state.to_string(-1))
        1
      end
      push(name)
      status = pcall(1, 1)
      unless status.ok?
        raise LuaAPIError.new
      end
    end

    def unsafe_get_global(name : String)
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
      String.new(LibLuaJIT.lua_tolstring(self, index, pointerof(size)) || Bytes[])
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
        begin
          Box(typeof(block)).unbox(ud).call(state)
        rescue err
          state.raise_error(err.inspect)
          0
        end
      end
      push(box)
      LibLuaJIT.lua_pushcclosure(self, proc, 1)
      self
    end

    def unsafe_push_cfunction(&block : CFunction) : Nil
      LibxLuaJIT.lua_pushcfunction(self, block)
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
    def pcall(nargs : Int32, nresults : Int32, errfunc : Int32 = 0) : LuaStatus
      LuaStatus.new(LibLuaJIT.lua_pcall(self, nargs, nresults, errfunc))
    end

    # Similar to `lua_cpcall`
    def c_pcall(&block : Function) : LuaStatus
      box = Box(typeof(block)).box(block)
      proc = CFunction.new do |l|
        state = LuaState.new(l)
        ud = state.to_userdata(-1)
        state.remove(-1)
        begin
          Box(typeof(block)).unbox(ud).call(state)
        rescue err
          state.raise_error(err.to_s)
          0
        end
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
      String.new(LibLuaJIT.lua_typename(self, lua_type.value) || Bytes[])
    end

    # Similar to `luaL_typename`
    #
    # Can also be created from a combination of `#get_type` and `#type_name`
    def type_name_at(index : Int32) : String
      LibxLuaJIT.luaL_typename(self, index)
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
      LuaError.check!(self, result)
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
      status = LuaStatus.new(LibxLuaJIT.luaL_dostring(self, code))
      LuaError.check!(self, status)
    end

    # Similar to `luaL_dofile`
    def execute(path : Path) : Nil
      status = LuaStatus.new(LibxLuaJIT.luaL_dofile(self, path))
      LuaError.check!(self, status)
    end

    # Crystal equivalent to `luaL_argerror`
    def raise_arg_error(pos : Int32, reason : String)
      new_pos = pos
      r, ar = get_stack(0)
      unless r # no stack frame?
        raise "bad argument ##{new_pos} (#{reason})"
      end
      r, ar = get_info("n", ar)
      if String.new(ar.namewhat || Bytes[]) == "method"
        new_pos -= 1 # do not count `self`
        if new_pos == 0 # error is in the self argument itself?
          raise "calling '#{String.new(ar.name || Bytes[])}' on bad self (#{reason})"
        end
      end
      raise "bad argument ##{new_pos} to '#{String.new(ar.name || "?".to_slice)}' (#{reason})"

      #new_pos = pos
      #r = LibLuaJIT.lua_getstack(self, 0, out ar)
      #if r == 0 # no stack frame?
        #raise "bad argument ##{new_pos} (#{reason})"
      #end
      #LibLuaJIT.lua_getinfo(self, "n", pointerof(ar))
      #if String.new(ar.namewhat || Bytes[]) == "method"
        #new_pos -= 1 # do not count `self`
        #if new_pos == 0 # error is in the self argument itself?
          #raise "calling '#{String.new(ar.name || Bytes[])}' on bad self (#{reason})"
        #end
      #end
      #raise "bad argument ##{new_pos} to '#{String.new(ar.name || "?".to_slice)}' (#{reason})"
    end

    # Crystal equivalent to `luaL_checkany`
    def assert_any?(index : Int32) : Nil
      if is_none?(index)
        raise_arg_error(index, "value expected")
      end
    end

    # Crystal equivalent to `luaL_checkinteger`
    def assert_integer?(index : Int32) : Nil
      if to_i64(index) == 0 && !is_number?(index) # avoid extra test when not 0
        raise_type_error(index, type_name(:number))
      end
    end

    # Crystal equivalent to `luaL_checklstring`
    def assert_string?(index : Int32, size : UInt64) : Nil
      unless LibLuaJIT.lua_tolstring(self, index, pointerof(size))
        raise_type_error(index, type_name(:string))
      end
    end

    # Crystal equivalent to `luaL_checkstring`
    def assert_string?(index : Int32) : Nil
      unless LibLuaJIT.lua_tolstring(self, index, nil)
        raise_type_error(index, type_name(:string))
      end
    end

    # Crystal equivalent to `luaL_checknumber`
    def assert_number?(index : Int32) : Nil
      if to_f64(index) == 0 && !is_number?(index) # avoid extra test when not 0
        raise_type_error(index, type_name(:number))
      end
    end

    # Crystal equivalent to `luaL_checktype`
    def assert_type?(index : Int32, type : LuaType) : Nil
      unless get_type(index) == type
        raise_type_error(index, type_name(type))
      end
    end

    # Crystal equivalent to `luaL_checkudata`
    def assert_userdata?(index : Int32, type : String) : Nil
      if LibLuaJIT.lua_touserdata(self, index) # value is a userdata?
        if get_metatable(index) != 0 # does it have a metatable?
          LibxLuaJIT.luaL_getmetatable(self, type) # get correct metatable
          if raw_eq(-1, -2) # does it have correct mt?
            pop(2) # remove both metatables
            return
          end
        end
      end
      raise_type_error(index, type) # else error
    end

    # Crystal equivalent to `luaL_typerror`
    def raise_type_error(pos : Int32, type : String)
      raise_arg_error(pos, "#{type} expected, got #{LibxLuaJIT.luaL_typename(self, pos)}")
    end

    # Similar to `luaL_typerror`
    def raise_type(pos : Int32, type : String)
      LibLuaJIT.luaL_typerror(self, pos, type)
    end

    # Similar to `luaL_ref`
    def create_ref(index : Int32) : Int32
      LibLuaJIT.luaL_ref(self, index)
    end

    # Similar to `luaL_unref`
    def remove_ref(index : Int32, ref : Int32) : Nil
      LibLuaJIT.luaL_unref(self, index, ref)
    end

    # Similar to `lua_ref`
    def create_registry_ref : Int32
      LibxLuaJIT.lua_ref(self)
    end

    # Similar to `lua_unref`
    def remove_registry_ref(ref : Int32) : Nil
      LibxLuaJIT.lua_unref(self, ref)
    end

    # Similar to `lua_getref`
    def get_registry_ref(ref : Int32) : Nil
      LibxLuaJIT.lua_getref(self, ref)
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

    # Same as `Luajit.add_trackable`
    def track(ptr : Pointer(Void)) : Nil
      Luajit.add_trackable(get_registry_address, ptr)
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

    # Same as `Luajit.remove_trackable`
    def untrack(ref : Reference) : Nil
      Luajit.remove_trackable(get_registry_address, ref)
    end

    def destroy_userdata(ref : Reference) : Nil
      untrack(ref)
    end

    def get_userdata(_type : U.class, index : Int32) : U forall U
      to_userdata(index).as(Pointer(U)).value
    end

    def builder : Builder
      Builder.new(self)
    end

    def to_any?(index : Int32 = -1) : LuaAny?
      case type = get_type(index)
      in .number?
        LuaAny.new(to_f(index))
      in .boolean?
        LuaAny.new(to_boolean(index))
      in .string?
        LuaAny.new(to_string(index))
      in .light_userdata?, .function?, .userdata?, .thread?
        push_value(index)
        LuaAny.new(LuaRef.new(create_registry_ref, type))
      in .table?
        LuaAny.new(to_h)
      in .none?, LuaType::Nil
        nil
      end
    end

    def to_h : Hash(String | Float64, LuaAny)
      LuaTableIterator.new(self).to_h
    end

    def to_a : Array(LuaAny)
      LuaAny.to_a(to_h)
    end

    def debug_stack : Nil
      count = -1
      size.downto(1) do |index|
        puts "(#{count}) [#{index}]: #{get_type(index)}"
        count -= 1
      end
    end

    ############
    # NEW CODE #
    ############

    ### ACCESS FUNCTIONS

    # lua_isnumber
    # [-0, +0, -]
    def is_number?(index : Int32) : Bool
      LibLuaJIT.lua_isnumber(self, index) == true.to_unsafe
    end

    # lua_isstring
    # [-0, +0, -]
    def is_string?(index : Int32) : Bool
      LibLuaJIT.lua_isstring(self, index) == true.to_unsafe
    end

    # lua_iscfunction
    # [-0, +0, -]
    def is_c_function?(index : Int32) : Bool
      LibLuaJIT.lua_iscfunction(self, index) == true.to_unsafe
    end

    # lua_isuserdata
    # [-0, +0, -]
    def is_userdata?(index : Int32) : Bool
      LibLuaJIT.lua_isuserdata(self, index) == true.to_unsafe
    end

    # lua_type
    # [-0, +0, -]
    def get_type(index : Int32) : LuaType
      LuaType.new(LibLuaJIT.lua_type(self, index))
    end

    # lua_typename
    # [-0, +0, -]
    def type_name(lua_type : LuaType) : String
      String.new(LibLuaJIT.lua_typename(self, lua_type.value) || Bytes[])
    end

    # :nodoc:
    LUA_EQUAL_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      index1 = -2
      index2 = -1
      state.push(LibLuaJIT.lua_equal(state, index1, index2) == true.to_unsafe)
      1
    end

    # lua_equal
    # [-0, +0, e]
    def eq(index1 : Int32, index2 : Int32) : Bool
      LibxLuaJIT.lua_pushcfunction(self, LUA_EQUAL_PROC)
      push_value(index1)
      push_value(index2)
      status = pcall(2, 1)
      unless status.ok?
        raise LuaAPIError.new
      end
      to_boolean(-1).tap do
        pop(1)
      end
    end

    # lua_rawequal
    # [-0, +0, -]
    def raw_eq(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_rawequal(self, index1, index2) == true.to_unsafe
    end

    # :nodoc:
    LUA_LESSTHAN_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      index1 = -2
      index2 = -1
      state.push(LibLuaJIT.lua_lessthan(state, index1, index2) == true.to_unsafe)
      1
    end

    # lua_lessthan
    # [-0, +0, e]
    def less_than(index1 : Int32, index2 : Int32) : Bool
      LibxLuaJIT.lua_pushcfunction(self, LUA_LESSTHAN_PROC)
      push_value(index1)
      push_value(index2)
      status = pcall(2, 1)
      unless status.ok?
        raise LuaAPIError.new
      end
      to_boolean(-1).tap do
        pop(1)
      end
    end

    # lua_tonumber
    # [-0, +0, -]
    def to_f64(index : Int32) : Float64
      LibLuaJIT.lua_tonumber(self, index)
    end

    # lua_tointeger
    # [-0, +0, -]
    def to_i64(index : Int32) : Int64
      LibLuaJIT.lua_tointeger(self, index)
    end

    # lua_toboolean
    # [-0, +0, -]
    def to_boolean(index : Int32) : Bool
      LibLuaJIT.lua_toboolean(self, index) == true.to_unsafe
    end

    # lua_tolstring
    # [-0, +0, m]
    def to_string(index : Int32, size : UInt64) : String
      String.new(LibLuaJIT.lua_tolstring(self, index, pointerof(size)) || Bytes[])
    end

    # lua_objlen
    # [-0, +0, -]
    def size_at(index : Int32) : UInt64
      LibLuaJIT.lua_objlen(self, index)
    end

    # lua_tocfunction
    # [-0, +0, -]
    def to_c_function?(index : Int32) : CFunction?
      proc = LibLuaJIT.lua_tocfunction(self, index)
      if proc.pointer
        proc
      end
    end

    # lua_touserdata
    # [-0, +0, -]
    def to_userdata?(index : Int32) : Pointer(Void)?
      if ptr = LibLuaJIT.lua_touserdata(self, index)
        ptr
      end
    end

    # lua_tothread
    # [-0, +0, -]
    def to_thread?(index : Int32) : LuaState?
      if ptr = LibLuaJIT.lua_tothread(self, index)
        LuaState.new(ptr)
      end
    end

    # lua_topointer
    # [-0, +0, -]
    def to_pointer?(index : Int32) : Pointer(Void)?
      if ptr = LibLuaJIT.lua_topointer(self, index)
        ptr
      end
    end

    ### BASIC STACK MANIPULATION

    # lua_gettop
    # [-0, +0, -]
    def size : Int32
      LibLuaJIT.lua_gettop(self)
    end

    # lua_settop
    # [-?, +?, -]
    def set_top(index : Int32) : Nil
      LibLuaJIT.lua_settop(self, index)
    end

    # lua_pushvalue
    # [-0, +1, -]
    def push_value(index : Int32) : Nil
      LibLuaJIT.lua_pushvalue(self, index)
    end

    # lua_remove
    # [-1, +0, -]
    def remove(index : Int32) : Nil
      LibLuaJIT.lua_remove(self, index)
    end

    # lua_insert
    # [-1, +1, -]
    def insert(index : Int32) : Nil
      LibLuaJIT.lua_insert(self, index)
    end

    # lua_replace
    # [-1, +0, -]
    def replace(index : Int32) : Nil
      LibLuaJIT.lua_replace(self, index)
    end

    # lua_xmove
    # [-?, +?, -]
    def xmove(from : LuaState, to : LuaState, n : Int32) : Nil
      LibLuaJIT.lua_xmove(from, to, n)
    end

    ### COROUTINE FUNCTIONS

    # lua_yield
    # [-?, +?, -]
    def co_yield(nresults : Int32) : Int32
      LibLuaJIT.lua_yield(self, nresults)
    end

    # lua_resume
    # [-?, +?, -]
    def co_resume(narg : Int32) : Int32
      LibLuaJIT.lua_resume(self, narg)
    end

    # lua_status
    # [-0, +0, -]
    def status : LuaStatus
      LuaStatus.new(LibLuaJIT.lua_status(self))
    end

    ### DEBUGGER FUNCTIONS

    # lua_getstack
    # [-0, +0, -]
    def get_stack(level : Int32) : Tuple(Bool, LibLuaJIT::Debug)
      result = LibLuaJIT.lua_getstack(self, level, out ar)
      {result == true.to_unsafe, ar}
    end

    # lua_getinfo
    # [-(0|1), +(0|1|2), m]
    def get_info(what : String, ar : LibLuaJIT::Debug) : Tuple(Bool, LibLuaJIT::Debug)
      result = LibLuaJIT.lua_getinfo(self, what, pointerof(ar))
      {result != 0, ar}
    end

    # lua_getlocal
    # [-0, +(0|1), -]
    def get_local(ar : LibLuaJIT::Debug, n : Int32 = 1) : String?
      if ptr = LibLuaJIT.lua_getlocal(self, pointerof(ar), n)
        String.new(ptr)
      end
    end

    # lua_setlocal
    # [-(0|1), +0, -]
    def set_local(ar : LibLuaJIT::Debug, n : Int32 = 1) : String?
      if ptr = LibLuaJIT.lua_setlocal(self, pointerof(ar), n)
        String.new(ptr)
      end
    end

    # lua_getupvalue
    # [-0, +(0|1), -]
    def get_up_value(fn_index : Int32, n : Int32) : String?
      if ptr = LibLuaJIT.lua_getupvalue(self, fn_index, n)
        String.new(ptr)
      end
    end

    # lua_setupvalue
    # [-(0|1), +0, -]
    def set_up_value(fn_index : Int32, n : Int32) : String?
      if ptr = LibLuaJIT.lua_setupvalue(self, fn_index, n)
        String.new(ptr)
      end
    end

    # lua_sethook
    # [-0, +0, -]
    def set_hook(f : LibLuaJIT::Hook, mask : Int32, count : Int32) : Nil
      LibLuaJIT.lua_sethook(self, f, mask, count)
    end

    # lua_gethook
    # [-0, +0, -]
    def get_hook : LibLuaJIT::Hook
      LibLuaJIT.lua_gethook(self)
    end

    # lua_gethookmask
    # [-0, +0, -]
    def get_hook_mask : Int32
      LibLuaJIT.lua_gethookmask(self)
    end

    # lua_gethookcount
    # [-0, +0, -]
    def get_hook_count : Int32
      LibLuaJIT.lua_gethookcount(self)
    end

    ### GC FUNCTIONS

    # lua_gc
    # [-0, +0, e]
    #def gc : LuaGC
      #LuaGC.new(to_unsafe)
    #end

    ### GET FUNCTIONS

    # :nodoc:
    LUA_GETTABLE_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      index = state.to_i(-1)
      LibLuaJIT.lua_gettable(state, index)
      1
    end

    # lua_gettable
    # [-1, +1, e]
    def get_table(index : Int32) : Nil
      LibxLuaJIT.lua_pushcfunction(self, LUA_GETTABLE_PROC)
      push(index)
      status = pcall(1, 1)
      unless status.ok?
        raise LuaAPIError.new
      end
    end

    # :nodoc:
    LUA_GETFIELD_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      index = state.to_i(-2)
      name = state.to_string(-1)
      LibLuaJIT.lua_getfield(state, index, name)
      1
    end

    # lua_getfield
    # [-0, +1, e]
    def get_field(index : Int32, name : String)
      LibxLuaJIT.lua_pushcfunction(self, LUA_GETFIELD_PROC)
      push(index)
      push(name)
      status = pcall(2, 1)
      unless status.ok?
        raise LuaAPIError.new
      end
    end

    # lua_rawget
    # [-1, +1, -]
    def raw_get(index : Int32) : Nil
      LibLuaJIT.lua_rawget(self, index)
    end

    # lua_rawgeti
    # [-0, +1, -]
    def raw_get_index(index : Int32, n : Int32) : Nil
      LibLuaJIT.lua_rawgeti(self, index, n)
    end

    # lua_createtable
    # [-0, +1, m]
    def create_table(narr : Int32, nrec : Int32) : Nil
      LibLuaJIT.lua_createtable(self, narr, nrec)
    end

    # lua_newuserdata
    # [-0, +1, m]
    def new_userdata(size : UInt64) : Pointer(Void)
      LibLuaJIT.lua_newuserdata(self, size)
    end

    # lua_getmetatable
    # [-0, +(0|1), -]
    def get_metatable(index : Int32) : Bool
      LibLuaJIT.lua_getmetatable(self, index) != 0
    end

    # lua_getfenv
    # [-0, +1, -]
    def get_fenv(index : Int32) : Nil
      LibLuaJIT.lua_getfenv(self, index)
    end

    ### LOAD FUNCTIONS

    # lua_pcall
    # [-(nargs + 1), +(nresults|1), -]
    def pcall(nargs : Int32, nresults : Int32, errfunc : Int32 = 0) : LuaStatus
      LuaStatus.new(LibLuaJIT.lua_pcall(self, nargs, nresults, errfunc))
    end

    # lua_cpcall
    # [-0, +(0|1), -]
    def c_pcall(&block : Function) : LuaStatus
      box = Box(typeof(block)).box(block)
      proc = CFunction.new do |l|
        state = LuaState.new(l)
        ud = state.to_userdata(-1)
        state.remove(-1)
        begin
          Box(typeof(block)).unbox(ud).call(state)
        rescue err
          state.raise_error(err.to_s)
          0
        end
      end
      LuaStatus.new(LibLuaJIT.lua_cpcall(self, proc, box))
    end

    # lua_load
    # [-0, +1, -]
    def load(chunk_name : String, &block : Loader) : LuaStatus
      box = Box(typeof(block)).box(block)
      proc = LibLuaJIT::Reader.new do |l, data, size|
        state = LuaState.new(l)
        Box(typeof(block)).unbox(data).call(state, size)
      end
      result = LuaStatus.new(LibLuaJIT.lua_load(self, proc, box, chunk_name))
      LuaError.check!(self, result)
      result
    end

    # lua_dump
    # [-0, +0, m]
    def dump(&block : Unloader) : Int32
      box = Box(typeof(block)).box(block)
      proc = LibLuaJIT::Writer.new do |l, ptr, size, ud|
        state = LuaState.new(l)
        Box(typeof(block)).unbox(ud).call(state, ptr, size)
      end
      LibLuaJIT.lua_dump(self, proc, box)
    end

    ### OTHER FUNCTIONS

    # :nodoc:
    LUA_NEXT_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      result = LibLuaJIT.lua_next(state, -2)
      if result != 0
        state.push(true)
      else
        state.push(nil)
        state.push(nil)
        state.push(false)
      end
      3
    end

    # lua_next
    # [-1, +(2|0), e]
    def next(index : Int32) : Bool
      push_value(index)
      insert(-2)
      LibxLuaJIT.lua_pushcfunction(self, LUA_NEXT_PROC)
      insert(-3)
      status = pcall(2, 3)
      unless status.ok?
        raise LuaAPIError.new
      end
      to_boolean(-1).tap do |result|
        pop(1)
        pop(2) unless result
      end
    end

    # :nodoc:
    LUA_CONCAT_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      n = state.size
      LibLuaJIT.lua_concat(state, n)
      1
    end

    # lua_concat
    # [-n, +1, e]
    def concat(n : Int32) : Nil
      if n < 1
        return push("")
      elsif n == 1
        return
      end

      LibxLuaJIT.lua_pushcfunction(self, LUA_CONCAT_PROC)
      insert(-(n) - 1)
      status = pcall(n, 1)
      unless status.ok?
        raise LuaAPIError.new
      end
    end

    ### PUSH FUNCTIONS

    # lua_pushnil
    # [-0, +1, -]
    def push(_x : Nil) : Nil
      LibLuaJIT.lua_pushnil(self)
    end

    # lua_pushnumber
    # [-0, +1, -]
    def push(x : Float64) : Nil
      LibLuaJIT.lua_pushnumber(self, x)
    end

    # lua_pushinteger
    # [-0, +1, -]
    def push(x : Int64) : Nil
      LibLuaJIT.lua_pushinteger(self, x)
    end

    # lua_pushstring
    # [-0, +1, m]
    def push(x : String) : Nil
      LibLuaJIT.lua_pushstring(self, x)
    end

    # lua_pushcclosure
    # [-n, +1, m]
    def push(&block : Function) : Nil
      box = Box(typeof(block)).box(block)
      track(box)
      proc = CFunction.new do |l|
        state = LuaState.new(l)
        ud = state.to_userdata(state.upvalue_at(1))
        begin
          Box(typeof(block)).unbox(ud).call(state)
        rescue err
          state.raise_error(err.inspect)
          0
        end
      end
      push(box)
      LibLuaJIT.lua_pushcclosure(self, proc, 1)
    end

    # lua_pushboolean
    # [-0, +1, -]
    def push(x : Bool) : Nil
      LibLuaJIT.lua_pushboolean(self, x)
    end

    # lua_pushlightuserdata
    # [-0, +1, -]
    def push(x : Pointer(Void)) : Nil
      LibLuaJIT.lua_pushlightuserdata(self, x)
    end

    # lua_pushthread
    # [-0, +1, -]
    def push_thread(x : LuaState) : ThreadStatus
      if LibLuaJIT.lua_pushthread(x) == 1
        ThreadStatus::Main
      else
        ThreadStatus::Coroutine
      end
    end

    ### SET FUNCTIONS

    # :nodoc:
    LUA_SETTABLE_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      LibLuaJIT.lua_settable(state, -3)
      0
    end

    # lua_settable
    # [-2, +0, e]
    def set_table(index : Int32) : Nil
      push_value(index)
      insert(-3)
      LibxLuaJIT.lua_pushcfunction(self, LUA_SETTABLE_PROC)
      insert(-4)
      status = pcall(3, 0)
      unless status.ok?
        raise LuaAPIError.new
      end
    end

    # :nodoc:
    LUA_SETFIELD_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      state.pop(1)
      LibLuaJIT.lua_setfield(state, -2, key)
      0
    end

    # lua_setfield
    # [-1, +0, e]
    def set_field(index : Int32, k : String) : Nil
      case index
      when LibLuaJIT::LUA_GLOBALSINDEX
        return set_global(k)
      when LibLuaJIT::LUA_REGISTRYINDEX
        return set_registry(k)
      when LibLuaJIT::LUA_ENVIRONINDEX
        return set_environment(k)
      end

      push_value(index)
      insert(-2)
      LibxLuaJIT.lua_pushcfunction(self, LUA_SETFIELD_PROC)
      insert(-3)
      push(k)
      status = pcall(3, 0)
      unless status.ok?
        raise LuaAPIError.new
      end
    end

    # :nodoc:
    LUA_SETGLOBAL_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      state.pop(1)
      LibLuaJIT.lua_setfield(state, LibLuaJIT::LUA_GLOBALSINDEX, key)
      0
    end

    # lua_setglobal
    # [-1, +0, e]
    def set_global(name : String) : Nil
      LibxLuaJIT.lua_pushcfunction(self, LUA_SETGLOBAL_PROC)
      insert(-2)
      push(name)
      status = pcall(2, 0)
      unless status.ok?
        raise LuaAPIError.new
      end
    end

    # :nodoc:
    LUA_SETREGISTRY_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      state.pop(1)
      LibLuaJIT.lua_setfield(state, LibLuaJIT::LUA_REGISTRYINDEX, key)
      0
    end

    # [-1, +0, e]
    def set_registry(name : String) : Nil
      LibxLuaJIT.lua_pushcfunction(self, LUA_SETREGISTRY_PROC)
      insert(-2)
      push(name)
      status = pcall(2, 0)
      unless status.ok?
        raise LuaAPIError.new
      end
    end

    # :nodoc:
    LUA_SETENVIRONMENT_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      state.pop(1)
      LibLuaJIT.lua_setfield(state, LibLuaJIT::LUA_ENVIRONINDEX, key)
      0
    end

    # [-1, +0, e]
    def set_environment(name : String) : Nil
      LibxLuaJIT.lua_pushcfunction(self, LUA_SETENVIRONMENT_PROC)
      insert(-2)
      push(name)
      status = pcall(2, 0)
      unless status.ok?
        raise LuaAPIError.new
      end
    end

    # lua_rawset
    # [-2, +0, m]
    def raw_set(index : Int32) : Nil
      LibLuaJIT.lua_rawset(self, index)
    end

    # lua_rawseti
    # [-1, +0, m]
    def raw_set_index(index : Int32, n : Int32) : Nil
      LibLuaJIT.lua_rawseti(self, index, n)
    end

    # lua_setmetatable
    # [-1, +0, -]
    def set_metatable(index : Int32) : Int32
      LibLuaJIT.lua_setmetatable(self, index)
    end

    # lua_setfenv
    # [-1, +0, -]
    def set_fenv(index : Int32) : Int32
      LibLuaJIT.lua_setfenv(self, index)
    end

    ### STATE MANIPULATION

    # lua_close
    # [-0, +0, -]
    def close : Nil
      LibLuaJIT.lua_close(self)
    end

    # lua_newthread
    # [-0, +1, m]
    def new_thread : LuaState
      LuaState.new(LibLuaJIT.lua_newthread(self))
    end

    # lua_atpanic
    # [-0, +0, -]
    def at_panic(&cb : CFunction) : CFunction
      LibLuaJIT.lua_atpanic(self, cb)
    end
  end
end
