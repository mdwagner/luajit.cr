module Luajit
  struct LuaState
    alias Function = LuaState -> Int32

    enum ThreadStatus
      Main
      Coroutine
    end

    # :nodoc:
    MT_NAME = metatable_name("__LuaState__")

    @ptr : Pointer(LibLuaJIT::State)

    def self.metatable_name(name : String) : String
      "luajit_cr::#{name}"
    end

    # :nodoc:
    #
    # Returns the pointer address of _state_
    def self.pointer_address(state : LuaState) : String
      state.to_unsafe.address.to_s
    end

    # :nodoc:
    #
    # Sets the _state_ pointer address inside it's own registry
    #
    # Used with `#get_registry_address` for tracking whether a LuaState
    # instance or thread is part of a parent LuaState instance
    def self.set_registry_address(state : LuaState) : Nil
      state.push(pointer_address(state))
      state.set_registry!(MT_NAME)
    end

    # :nodoc:
    LUA_ATPANIC_PROC = LuaCFunction.new do |l|
      state = LuaState.new(l)
      STDERR.puts state.at_panic_default_error_message
      0
    end

    def self.create : LuaState
      new(LibLuaJIT.luaL_newstate).tap do |state|
        state.at_panic(LUA_ATPANIC_PROC)
        set_registry_address(state)
      end
    end

    def self.destroy(state : LuaState) : Nil
      begin
        Trackable.remove(pointer_address(state))
      ensure
        state.close
      end
    end

    def initialize(@ptr)
    end

    def to_unsafe
      @ptr
    end

    # :nodoc:
    #
    # Returns the LuaState pointer address inside the registry
    #
    # Works across the main thread and child threads
    def get_registry_address : String
      get_registry!(MT_NAME)
      to_string(-1).tap do
        pop(1)
      end
    end

    # Returns the version number of this core
    def version : Float64
      LibLuaJIT.lua_version(self).value
    end

    ### LUA LIBRARY FUNCTIONS

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

    ### ACCESS FUNCTIONS

    # Returns `true` if value at the given *index* has type boolean
    #
    # Lua: `lua_isboolean`, `[-0, +0, -]`
    def is_bool?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TBOOLEAN
    end

    # Returns `true` if value at the given *index* is a number or a string convertible to a number
    #
    # Lua: `lua_isnumber`, `[-0, +0, -]`
    def is_number?(index : Int32) : Bool
      LibLuaJIT.lua_isnumber(self, index) == true.to_unsafe
    end

    # Returns `true` if value at the given *index* is a string or a number (which is always convertible to a string)
    #
    # Lua: `lua_isstring`, `[-0, +0, -]`
    def is_string?(index : Int32) : Bool
      LibLuaJIT.lua_isstring(self, index) == true.to_unsafe
    end

    # Returns `true` if value at the given *index* is a function (either C or Lua)
    #
    # Lua: `lua_isfunction`, `[-0, +0, -]`
    def is_function?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TFUNCTION
    end

    # Returns `true` if value at the given *index* is a C function
    #
    # Lua: `lua_iscfunction`, `[-0, +0, -]`
    def is_c_function?(index : Int32) : Bool
      LibLuaJIT.lua_iscfunction(self, index) == true.to_unsafe
    end

    # Returns `true` if value at the given *index* is a userdata (either full or light)
    #
    # Lua: `lua_isuserdata`, `[-0, +0, -]`
    def is_userdata?(index : Int32) : Bool
      LibLuaJIT.lua_isuserdata(self, index) == true.to_unsafe
    end

    # Returns `true` if value at the given *index* is a light userdata
    #
    # Lua: `lua_islightuserdata`, `[-0, +0, -]`
    def is_light_userdata?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TLIGHTUSERDATA
    end

    # Returns `true` if value at the given *index* is a thread
    #
    # Lua: `lua_isthread`, `[-0, +0, -]`
    def is_thread?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TTHREAD
    end

    # Returns `true` if value at the given *index* is a table
    #
    # Lua: `lua_istable`, `[-0, +0, -]`
    def is_table?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TTABLE
    end

    # Returns `true` if value at the given *index* is nil
    #
    # Lua: `lua_isnil`, `[-0, +0, -]`
    def is_nil?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TNIL
    end

    # Returns `true` if value at the given *index* is not valid (refers to an element outside the current stack)
    #
    # Lua: `lua_isnone`, `[-0, +0, -]`
    def is_none?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TNONE
    end

    # Returns `true` if value at the given *index* is not valid (refers to an element outside the current stack) or is nil
    #
    # Lua: `lua_isnoneornil`, `[-0, +0, -]`
    def is_none_or_nil?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) <= 0
    end

    # Returns the type of the value at the given *index*
    #
    # Lua: `lua_type`, `[-0, +0, -]`
    def get_type(index : Int32) : LuaType
      LuaType.new(LibLuaJIT.lua_type(self, index))
    end

    # Returns the name of the *lua_type* value
    #
    # Lua: `lua_typename`, `[-0, +0, -]`
    def type_name(lua_type : LuaType) : String
      String.new(LibLuaJIT.lua_typename(self, lua_type.value) || Bytes[])
    end

    # Returns the name of the type of the value at the given *index*
    #
    # Lua: `luaL_typename`, `[-0, +0, -]`
    def type_name_at(index : Int32) : String
      String.new(LibLuaJIT.lua_typename(self, LibLuaJIT.lua_type(self, index)) || Bytes[])
    end

    # :nodoc:
    LUA_EQUAL_PROC = LuaCFunction.new do |l|
      state = LuaState.new(l)
      index1 = -2
      index2 = -1
      state.push(LibLuaJIT.lua_equal(state, index1, index2) == true.to_unsafe)
      1
    end

    # Returns `true` if the two values in indices *index1* and *index2* are equal
    #
    # Follows the semantics of the Lua `==` operator (i.e. may call metamethods)
    #
    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_equal`, `[-0, +0, e]`
    def eq!(index1 : Int32, index2 : Int32) : Bool
      index1 = abs_index(index1)
      index2 = abs_index(index2)
      push_value(index1)
      push_value(index2)
      push(LUA_EQUAL_PROC)
      insert(-3)
      pcall(2, 1).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, "lua_equal")
        end
      end
      to_boolean(-1).tap do
        pop(1)
      end
    end

    # Returns `true` if the two values in indices *index1* and *index2* are primitively equal
    #
    # Does not call metamethods
    #
    # Lua: `lua_rawequal`, `[-0, +0, -]`
    def raw_eq(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_rawequal(self, index1, index2) == true.to_unsafe
    end

    # :nodoc:
    LUA_LESSTHAN_PROC = LuaCFunction.new do |l|
      state = LuaState.new(l)
      index1 = -2
      index2 = -1
      state.push(LibLuaJIT.lua_lessthan(state, index1, index2) == true.to_unsafe)
      1
    end

    # Returns `true` if the value at *index1* is smaller than the value at *index2*
    #
    # Follows the semantics of the Lua `<` operator (i.e. may call metamethods)
    #
    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_lessthan`, `[-0, +0, e]`
    def less_than!(index1 : Int32, index2 : Int32) : Bool
      index1 = abs_index(index1)
      index2 = abs_index(index2)
      push_value(index1)
      push_value(index2)
      push(LUA_LESSTHAN_PROC)
      insert(-3)
      pcall(2, 1).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, "lua_lessthan")
        end
      end
      to_boolean(-1).tap do
        pop(1)
      end
    end

    # Converts the Lua value at *index* to `Float64`
    #
    # The value must be a number or a string convertible to a number, otherwise returns 0
    #
    # Lua: `lua_tonumber`, `[-0, +0, -]`
    def to_f64(index : Int32) : Float64
      LibLuaJIT.lua_tonumber(self, index)
    end

    # :ditto:
    def to_f(index : Int32) : Float64
      to_f64(index)
    end

    # Same as `#to_f64` but returns a `Float32`
    def to_f32(index : Int32) : Float32
      to_f64(index).to_f32
    end

    # Converts the Lua value at *index* to `Int64`
    #
    # The value must be a number or a string convertible to a number, otherwise returns 0
    #
    # If the number is not an integer, it is truncated in some non-specific way
    #
    # Lua: `lua_tointeger`, `[-0, +0, -]`
    def to_i64(index : Int32) : Int64
      LibLuaJIT.lua_tointeger(self, index)
    end

    # Same as `#to_i64` but returns a `Int32`
    def to_i32(index : Int32) : Int32
      to_i64(index).to_i
    end

    # :ditto:
    def to_i(index : Int32) : Int32
      to_i32(index)
    end

    # Converts the Lua value at *index* to `Bool`
    #
    # Returns `true` for any Lua value different than `false` or `nil`
    #
    # Returns `false` when called with a non-valid index
    #
    # Lua: `lua_toboolean`, `[-0, +0, -]`
    def to_boolean(index : Int32) : Bool
      LibLuaJIT.lua_toboolean(self, index) == true.to_unsafe
    end

    # Lua: `lua_tolstring`, `[-0, +0, m]`
    def to_string(index : Int32, size : UInt64) : String
      String.new(LibLuaJIT.lua_tolstring(self, index, pointerof(size)) || Bytes[])
    end

    # Lua: `lua_tostring`, `[-0, +0, m]`
    def to_string(index : Int32) : String
      String.new(LibLuaJIT.lua_tolstring(self, index, nil) || Bytes[])
    end

    # Lua: `lua_objlen`, `[-0, +0, -]`
    def size_at(index : Int32) : UInt64
      LibLuaJIT.lua_objlen(self, index)
    end

    # Lua: `lua_tocfunction`, `[-0, +0, -]`
    def to_c_function?(index : Int32) : LuaCFunction?
      proc = LibLuaJIT.lua_tocfunction(self, index)
      if proc.pointer
        proc
      end
    end

    # :ditto:
    def to_c_function!(index : Int32) : LuaCFunction
      to_c_function?(index).not_nil!
    end

    # Lua: `lua_touserdata`, `[-0, +0, -]`
    def to_userdata?(index : Int32) : Pointer(Void)?
      if ptr = LibLuaJIT.lua_touserdata(self, index)
        ptr
      end
    end

    # :ditto:
    def to_userdata!(index : Int32) : Pointer(Void)
      to_userdata?(index).not_nil!
    end

    # Lua: `lua_tothread`, `[-0, +0, -]`
    def to_thread?(index : Int32) : LuaState?
      if ptr = LibLuaJIT.lua_tothread(self, index)
        LuaState.new(ptr)
      end
    end

    # :ditto:
    def to_thread!(index : Int32) : LuaState
      to_thread?(index).not_nil!
    end

    # Lua: `lua_topointer`, `[-0, +0, -]`
    def to_pointer?(index : Int32) : Pointer(Void)?
      if ptr = LibLuaJIT.lua_topointer(self, index)
        ptr
      end
    end

    # :ditto:
    def to_pointer!(index : Int32) : Pointer(Void)
      to_pointer?(index).not_nil!
    end

    ### BASIC STACK MANIPULATION

    # Lua: `lua_gettop`, `[-0, +0, -]`
    def size : Int32
      LibLuaJIT.lua_gettop(self)
    end

    # Lua: `lua_settop`, `[-?, +?, -]`
    def set_top(index : Int32) : Nil
      LibLuaJIT.lua_settop(self, index)
    end

    # Lua: `lua_pop`, `[-n, +0, -]`
    def pop(n : Int32) : Nil
      set_top(-(n) - 1)
    end

    # Lua: `lua_pushvalue`, `[-0, +1, -]`
    def push_value(index : Int32) : Nil
      LibLuaJIT.lua_pushvalue(self, index)
    end

    # Lua: `lua_remove`, `[-1, +0, -]`
    def remove(index : Int32) : Nil
      case index
      when LibLuaJIT::LUA_GLOBALSINDEX, LibLuaJIT::LUA_REGISTRYINDEX, LibLuaJIT::LUA_ENVIRONINDEX
        raise LuaArgumentError.new("cannot be called with a pseudo-index")
      end

      LibLuaJIT.lua_remove(self, index)
    end

    # Lua: `lua_insert`, `[-1, +1, -]`
    def insert(index : Int32) : Nil
      case index
      when LibLuaJIT::LUA_GLOBALSINDEX, LibLuaJIT::LUA_REGISTRYINDEX, LibLuaJIT::LUA_ENVIRONINDEX
        raise LuaArgumentError.new("cannot be called with a pseudo-index")
      end

      LibLuaJIT.lua_insert(self, index)
    end

    # Lua: `lua_replace`, `[-1, +0, -]`
    def replace(index : Int32) : Nil
      LibLuaJIT.lua_replace(self, index)
    end

    # Lua: `lua_xmove`, `[-?, +?, -]`
    def xmove(from : LuaState, to : LuaState, n : Int32) : Nil
      LibLuaJIT.lua_xmove(from, to, n)
    end

    ### COROUTINE FUNCTIONS

    # Lua: `lua_yield`, `[-?, +?, -]`
    def co_yield(nresults : Int32) : Int32
      LibLuaJIT.lua_yield(self, nresults)
    end

    # Lua: `lua_resume`, `[-?, +?, -]`
    def co_resume(narg : Int32) : Int32
      LibLuaJIT.lua_resume(self, narg)
    end

    # Lua: `lua_status`, `[-0, +0, -]`
    def status : LuaStatus
      LuaStatus.new(LibLuaJIT.lua_status(self))
    end

    ### DEBUGGER FUNCTIONS

    # Lua: `lua_getstack`, `[-0, +0, -]`
    def get_stack(level : Int32) : LuaDebug?
      if LibLuaJIT.lua_getstack(self, level, out ar) == true.to_unsafe
        LuaDebug.new(ar)
      end
    end

    # Lua: `lua_getinfo`, `[-(0|1), +(0|1|2), m]`
    def get_info(what : String, ar : LuaDebug) : LuaDebug?
      if LibLuaJIT.lua_getinfo(self, what, ar) != 0
        ar
      end
    end

    # Lua: `lua_getlocal`, `[-0, +(0|1), -]`
    def get_local(ar : LuaDebug, n : Int32 = 1) : String?
      if ptr = LibLuaJIT.lua_getlocal(self, ar, n)
        String.new(ptr)
      end
    end

    # Lua: `lua_setlocal`, `[-(0|1), +0, -]`
    def set_local(ar : LuaDebug, n : Int32 = 1) : String?
      if ptr = LibLuaJIT.lua_setlocal(self, ar, n)
        String.new(ptr)
      end
    end

    # Lua: `lua_getupvalue`, `[-0, +(0|1), -]`
    def get_upvalue(fn_index : Int32, n : Int32) : String?
      if ptr = LibLuaJIT.lua_getupvalue(self, fn_index, n)
        String.new(ptr)
      end
    end

    # Lua: `lua_upvalueindex`
    def upvalue(index : Int32) : Int32
      LibLuaJIT::LUA_GLOBALSINDEX - index
    end

    # Lua: `lua_setupvalue`, `[-(0|1), +0, -]`
    def set_upvalue(fn_index : Int32, n : Int32) : String?
      if ptr = LibLuaJIT.lua_setupvalue(self, fn_index, n)
        String.new(ptr)
      end
    end

    # Lua: `lua_sethook`, `[-0, +0, -]`
    def set_hook(f : LibLuaJIT::Hook, mask : Int32, count : Int32) : Nil
      LibLuaJIT.lua_sethook(self, f, mask, count)
    end

    # Lua: `lua_gethook`, `[-0, +0, -]`
    def get_hook : LibLuaJIT::Hook
      LibLuaJIT.lua_gethook(self)
    end

    # Lua: `lua_gethookmask`, `[-0, +0, -]`
    def get_hook_mask : Int32
      LibLuaJIT.lua_gethookmask(self)
    end

    # Lua: `lua_gethookcount`, `[-0, +0, -]`
    def get_hook_count : Int32
      LibLuaJIT.lua_gethookcount(self)
    end

    # :nodoc:
    #
    # TODO
    def print_stack(uniq_value : String? = nil) : Nil
      puts "####{uniq_value || ""}"
      total = size
      if total == 0
        puts "# [0]"
      else
        count = -1
        total.downto(1) do |index|
          puts "# (#{count}) [#{index}]: #{get_type(index)}"
          count -= 1
        end
      end
      puts "###"
      puts
    end

    ### GC FUNCTIONS

    # Lua: `lua_gc`, `[-0, +0, e]`
    def gc : LuaGC
      LuaGC.new(self)
    end

    ### GET FUNCTIONS

    # :nodoc:
    LUA_GETTABLE_PROC = LuaCFunction.new do |l|
      state = LuaState.new(l)
      LibLuaJIT.lua_gettable(state, -2)
      1
    end

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_gettable`, `[-1, +1, e]`
    def get_table!(index : Int32) : Nil
      push_value(index)
      insert(-2)
      push(LUA_GETTABLE_PROC)
      insert(-3)
      pcall(2, 1).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, "lua_gettable")
        end
      end
    end

    # :nodoc:
    LUA_GETFIELD_PROC = LuaCFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      state.pop(1)
      LibLuaJIT.lua_getfield(state, -1, key)
      1
    end

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_getfield`, `[-0, +1, e]`
    def get_field!(index : Int32, name : String) : Nil
      case index
      when LibLuaJIT::LUA_GLOBALSINDEX
        raise LuaArgumentError.new("called with 'LUA_GLOBALSINDEX', must use 'LuaState#get_global!' instead")
      when LibLuaJIT::LUA_REGISTRYINDEX
        raise LuaArgumentError.new("called with 'LUA_REGISTRYINDEX', must use 'LuaState#get_registry!' instead")
      when LibLuaJIT::LUA_ENVIRONINDEX
        raise LuaArgumentError.new("called with 'LUA_ENVIRONINDEX', must use 'LuaState#get_environment!' instead")
      end

      push_value(index)
      push(LUA_GETFIELD_PROC)
      insert(-2)
      push(name)
      pcall(2, 1).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, "lua_getfield")
        end
      end
    end

    # :nodoc:
    LUA_GETGLOBAL_PROC = LuaCFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      LibLuaJIT.lua_getfield(state, LibLuaJIT::LUA_GLOBALSINDEX, key)
      1
    end

    # Raises `LuaProtectedError` if underlying operation failed
    def get_global!(name : String) : Nil
      push(LUA_GETGLOBAL_PROC)
      push(name)
      pcall(1, 1).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, "LuaState#get_global!")
        end
      end
    end

    # :nodoc:
    LUA_GETREGISTRY_PROC = LuaCFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      LibLuaJIT.lua_getfield(state, LibLuaJIT::LUA_REGISTRYINDEX, key)
      1
    end

    # Raises `LuaProtectedError` if underlying operation failed
    def get_registry!(name : String) : Nil
      push(LUA_GETREGISTRY_PROC)
      push(name)
      pcall(1, 1).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, "LuaState#get_registry!")
        end
      end
    end

    # Lua: `luaL_getmetatable`, `[-0, +1, -]`
    def get_metatable(tname : String) : Nil
      get_registry!(tname)
    end

    # :nodoc:
    LUA_GETENVIRONMENT_PROC = LuaCFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      LibLuaJIT.lua_getfield(state, LibLuaJIT::LUA_ENVIRONINDEX, key)
      1
    end

    # Raises `LuaProtectedError` if underlying operation failed
    def get_environment!(name : String) : Nil
      push(LUA_GETENVIRONMENT_PROC)
      push(name)
      pcall(1, 1).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, "LuaState#get_environment!")
        end
      end
    end

    # Lua: `lua_rawget`, `[-1, +1, -]`
    def raw_get(index : Int32) : Nil
      LibLuaJIT.lua_rawget(self, index)
    end

    # Lua: `lua_rawgeti`, `[-0, +1, -]`
    def raw_get_index(index : Int32, n : Int32) : Nil
      LibLuaJIT.lua_rawgeti(self, index, n)
    end

    # Lua: `lua_createtable`, `[-0, +1, m]`
    def create_table(narr : Int32, nrec : Int32) : Nil
      LibLuaJIT.lua_createtable(self, narr, nrec)
    end

    # Lua: `lua_newtable`
    def new_table : Nil
      create_table(0, 0)
    end

    # Lua: `lua_newuserdata`, `[-0, +1, m]`
    def new_userdata(size : UInt64) : Pointer(Void)
      LibLuaJIT.lua_newuserdata(self, size)
    end

    # Lua: `lua_getmetatable`, `[-0, +(0|1), -]`
    def get_metatable(index : Int32) : Bool
      LibLuaJIT.lua_getmetatable(self, index) != 0
    end

    # Lua: `lua_getfenv`, `[-0, +1, -]`
    def get_fenv(index : Int32) : Nil
      LibLuaJIT.lua_getfenv(self, index)
    end

    ### LOAD FUNCTIONS

    # Lua: `lua_pcall`, `[-(nargs + 1), +(nresults|1), -]`
    def pcall(nargs : Int32, nresults : Int32, errfunc : Int32 = 0) : LuaStatus
      case errfunc
      when LibLuaJIT::LUA_GLOBALSINDEX, LibLuaJIT::LUA_REGISTRYINDEX, LibLuaJIT::LUA_ENVIRONINDEX
        raise LuaArgumentError.new("'errfunc' argument cannot be a pseudo-index")
      end

      LuaStatus.new(LibLuaJIT.lua_pcall(self, nargs, nresults, errfunc))
    end

    # Lua Compat 5.3
    def c_pcall(&block : Function) : LuaStatus
      push(block)
      pcall(0, 0)
    end

    # Lua: `luaL_dostring`, `[-0, +?, m]`
    def execute(str : String) : LuaStatus
      status = LuaStatus.new(LibLuaJIT.luaL_loadstring(self, str))
      return pcall(0, LibLuaJIT::LUA_MULTRET) if status.ok?
      status
    end

    # Raises `LuaProtectedError` if underlying operation failed
    def execute!(str : String) : Nil
      status = execute(str)
      raise LuaProtectedError.new(self, status, "LuaState#execute!(String)") unless status.ok?
    end

    # Lua: `luaL_dofile`, `[-0, +?, m]`
    def execute(path : Path) : LuaStatus
      status = LuaStatus.new(LibLuaJIT.luaL_loadfile(self, path.to_s))
      return pcall(0, LibLuaJIT::LUA_MULTRET) if status.ok?
      status
    end

    # Raises `LuaProtectedError` if underlying operation failed
    def execute!(path : Path) : Nil
      status = execute(path)
      raise LuaProtectedError.new(self, status, "LuaState#execute!(Path)") unless status.ok?
    end

    ### OTHER FUNCTIONS

    # :nodoc:
    LUA_NEXT_PROC = LuaCFunction.new do |l|
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

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_next`, `[-1, +(2|0), e]`
    def next!(index : Int32) : Bool
      push_value(index)
      insert(-2)
      push(LUA_NEXT_PROC)
      insert(-3)
      pcall(2, 3).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, "lua_next")
        end
      end
      to_boolean(-1).tap do |result|
        pop(1)
        pop(2) unless result
      end
    end

    # :nodoc:
    LUA_CONCAT_PROC = LuaCFunction.new do |l|
      state = LuaState.new(l)
      n = state.size
      LibLuaJIT.lua_concat(state, n)
      1
    end

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_concat`, `[-n, +1, e]`
    def concat!(n : Int32) : Nil
      if n < 1
        push("")
        return
      elsif n == 1
        return
      end

      push(LUA_CONCAT_PROC)
      insert(-(n) - 1)
      pcall(n, 1).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, "lua_concat")
        end
      end
    end

    ### PUSH FUNCTIONS

    # Lua: `lua_pushnil`, `[-0, +1, -]`
    def push(_x : Nil) : Nil
      LibLuaJIT.lua_pushnil(self)
    end

    # Lua: `lua_pushnumber`, `[-0, +1, -]`
    def push(x : Float64) : Nil
      LibLuaJIT.lua_pushnumber(self, x)
    end

    def push(x : Float32) : Nil
      push(x.to_f64)
    end

    # Lua: `lua_pushinteger`, `[-0, +1, -]`
    def push(x : Int64) : Nil
      LibLuaJIT.lua_pushinteger(self, x)
    end

    def push(x : Int32) : Nil
      push(x.to_i64)
    end

    # Lua: `lua_pushstring`, `[-0, +1, m]`
    def push(x : String) : Nil
      LibLuaJIT.lua_pushstring(self, x)
    end

    def push(x : Char) : Nil
      push(x.to_s)
    end

    def push(x : Symbol) : Nil
      push(x.to_s)
    end

    # Lua: `lua_pushcfunction`, `[-n, +1, m]`
    def push(x : LuaCFunction) : Nil
      LibLuaJIT.lua_pushcclosure(self, x, 0)
    end

    # Lua: `lua_pushcclosure`, `[-n, +1, m]`
    def push(x : Function) : Nil
      push_fn_closure do |state|
        x.call(state)
      end
    end

    # Lua: `lua_pushboolean`, `[-0, +1, -]`
    def push(x : Bool) : Nil
      LibLuaJIT.lua_pushboolean(self, x)
    end

    # Lua: `lua_pushlightuserdata`, `[-0, +1, -]`
    def push(x : Pointer(Void)) : Nil
      LibLuaJIT.lua_pushlightuserdata(self, x)
    end

    def push(x : Array) : Nil
      create_table(x.size, 0)
      x.each_with_index do |item, index|
        push(index + 1)
        push(item)
        set_table(-3)
      end
    end

    def push(x : Hash) : Nil
      create_table(0, x.size)
      x.each do |key, value|
        push(key)
        push(value)
        set_table(-3)
      end
    end

    # Lua: `lua_pushcfunction`, `[-n, +1, m]`
    def push_fn(&block : LuaCFunction) : Nil
      push(block)
    end

    # Lua: `lua_pushcclosure`, `[-n, +1, m]`
    def push_fn_closure(&block : Function) : Nil
      box = Box(typeof(block)).box(block)
      track(box)
      proc = LuaCFunction.new do |l|
        state = LuaState.new(l)
        begin
          Box(typeof(block)).unbox(state.to_userdata!(state.upvalue(1))).call(state)
        rescue err
          LibLuaJIT.luaL_error(state, err.inspect)
        end
      end
      push(box)
      LibLuaJIT.lua_pushcclosure(self, proc, 1)
    end

    # Lua: `lua_pushthread`, `[-0, +1, -]`
    def push_thread(x : LuaState) : ThreadStatus
      if LibLuaJIT.lua_pushthread(x) == 1
        ThreadStatus::Main
      else
        ThreadStatus::Coroutine
      end
    end

    ### SET FUNCTIONS

    # :nodoc:
    LUA_SETTABLE_PROC = LuaCFunction.new do |l|
      state = LuaState.new(l)
      LibLuaJIT.lua_settable(state, -3)
      0
    end

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_settable`, `[-2, +0, e]`
    def set_table!(index : Int32) : Nil
      push_value(index)
      insert(-3)
      push(LUA_SETTABLE_PROC)
      insert(-4)
      pcall(3, 0).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, "lua_settable")
        end
      end
    end

    # :nodoc:
    LUA_SETFIELD_PROC = LuaCFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      state.pop(1)
      LibLuaJIT.lua_setfield(state, -2, key)
      0
    end

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_setfield`, `[-1, +0, e]`
    def set_field!(index : Int32, k : String) : Nil
      case index
      when LibLuaJIT::LUA_GLOBALSINDEX
        raise LuaArgumentError.new("called with 'LUA_GLOBALSINDEX', must use 'LuaState#set_global!' instead")
      when LibLuaJIT::LUA_REGISTRYINDEX
        raise LuaArgumentError.new("called with 'LUA_REGISTRYINDEX', must use 'LuaState#set_registry!' instead")
      when LibLuaJIT::LUA_ENVIRONINDEX
        raise LuaArgumentError.new("called with 'LUA_ENVIRONINDEX', must use 'LuaState#set_environment!' instead")
      end

      push_value(index)
      insert(-2)
      push(LUA_SETFIELD_PROC)
      insert(-3)
      push(k)
      pcall(3, 0).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, "lua_setfield")
        end
      end
    end

    # :nodoc:
    LUA_SETGLOBAL_PROC = LuaCFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      state.pop(1)
      LibLuaJIT.lua_setfield(state, LibLuaJIT::LUA_GLOBALSINDEX, key)
      0
    end

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_setglobal`, `[-1, +0, e]`
    def set_global!(name : String) : Nil
      push(LUA_SETGLOBAL_PROC)
      insert(-2)
      push(name)
      pcall(2, 0).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, "lua_setglobal")
        end
      end
    end

    # :nodoc:
    LUA_SETREGISTRY_PROC = LuaCFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      state.pop(1)
      LibLuaJIT.lua_setfield(state, LibLuaJIT::LUA_REGISTRYINDEX, key)
      0
    end

    # Raises `LuaProtectedError` if underlying operation failed
    def set_registry!(name : String) : Nil
      push(LUA_SETREGISTRY_PROC)
      insert(-2)
      push(name)
      pcall(2, 0).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, "LuaState#set_registry!")
        end
      end
    end

    # :nodoc:
    LUA_SETENVIRONMENT_PROC = LuaCFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      state.pop(1)
      LibLuaJIT.lua_setfield(state, LibLuaJIT::LUA_ENVIRONINDEX, key)
      0
    end

    # Raises `LuaProtectedError` if underlying operation failed
    def set_environment!(name : String) : Nil
      push(LUA_SETENVIRONMENT_PROC)
      insert(-2)
      push(name)
      pcall(2, 0).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, "LuaState#set_environment!")
        end
      end
    end

    # Registers a global function
    #
    # Lua: `lua_register`
    def register_fn_global(name : String, &block : Function) : Nil
      push(block)
      set_global(name)
    end

    # Registers a named function to table at the top of the stack
    def register_fn(name : String, &block : Function) : Nil
      assert_table?(-1)
      push(name)
      push(block)
      set_table(-3)
    end

    # TODO
    # Lua Compat 5.3
    #def get_subtable(index : Int32, fname : String) : Bool
    #end

    # TODO
    # Lua Compat 5.3
    #def requiref(modname : String, openf : LuaCFunction, glb : Bool = false) : Nil
    #end

    # TODO
    # - use `requiref` as baseline
    def register(l : Library) : Nil
      raise NotImplementedError.new("register(Library)")
    end

    def register_library(name : String, & : Library ->) : Nil
      l = Library.new(name)
      yield l
      register(l)
    end

    # Lua: `luaL_register`, `[-(0|1), +1, m]`
    def register(name : String, regs : Array(LuaReg)) : Nil
      libs = [] of LibLuaJIT::Reg
      regs.each do |reg|
        libs << LibLuaJIT::Reg.new(name: reg.name, func: reg.function.pointer)
      end
      libs << LibLuaJIT::Reg.new(name: Pointer(UInt8).null, func: Pointer(Void).null)
      LibLuaJIT.luaL_register(self, name, libs)
    end

    # Lua: `luaL_register`, `[-(0|1), +1, m]`
    def register(regs : Array(LuaReg)) : Nil
      libs = [] of LibLuaJIT::Reg
      regs.each do |reg|
        libs << LibLuaJIT::Reg.new(name: reg.name, func: reg.function.pointer)
      end
      libs << LibLuaJIT::Reg.new(name: Pointer(UInt8).null, func: Pointer(Void).null)
      LibLuaJIT.luaL_register(self, Pointer(UInt8).null, libs)
    end

    # Lua: `lua_rawset`, `[-2, +0, m]`
    def raw_set(index : Int32) : Nil
      LibLuaJIT.lua_rawset(self, index)
    end

    # Lua: `lua_rawseti`, `[-1, +0, m]`
    def raw_set_index(index : Int32, n : Int32) : Nil
      LibLuaJIT.lua_rawseti(self, index, n)
    end

    # Lua: `lua_setmetatable`, `[-1, +0, -]`
    def set_metatable(index : Int32) : Int32
      LibLuaJIT.lua_setmetatable(self, index)
    end

    # Lua: `lua_setfenv`, `[-1, +0, -]`
    def set_fenv(index : Int32) : Int32
      LibLuaJIT.lua_setfenv(self, index)
    end

    # Lua: `luaL_newmetatable`, `[-0, +1, m]`
    def new_metatable(tname : String) : Bool
      LibLuaJIT.luaL_newmetatable(self, tname) != 0
    end

    # Lua: `luaL_getmetafield`, `[-0, +(0|1), m]`
    def get_metafield(obj : Int32, e : String) : Bool
      LibLuaJIT.luaL_getmetafield(self, obj, e) != 0
    end

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `luaL_callmeta`, `[-0, +(0|1), e]`
    def call_metamethod!(obj : Int32, event : String) : Bool
      obj = abs_index(obj)
      if get_metafield(obj, event)
        push_value(obj)
        pcall(1, 1).tap do |status|
          unless status.ok?
            raise LuaProtectedError.new(self, status, "LuaState#call_metamethod!")
          end
        end
        true
      else
        false
      end
    end

    # Lua Compat 5.3
    def abs_index(index : Int32) : Int32
      if index > 0 || index <= LibLuaJIT::LUA_REGISTRYINDEX
        index
      else
        size + index + 1
      end
    end

    ### STATE MANIPULATION

    # Lua: `lua_close`, `[-0, +0, -]`
    def close : Nil
      LibLuaJIT.lua_close(self)
    end

    # Lua: `lua_newthread`, `[-0, +1, m]`
    def new_thread : LuaState
      LuaState.new(LibLuaJIT.lua_newthread(self))
    end

    # Lua: `lua_atpanic`, `[-0, +0, -]`
    def at_panic(cb : LuaCFunction) : LuaCFunction
      LibLuaJIT.lua_atpanic(self, cb)
    end

    # :ditto:
    def at_panic(&block : LuaCFunction) : LuaCFunction
      at_panic(block)
    end

    # :nodoc:
    def at_panic_default_error_message : String
      String.build do |str|
        str << "PANIC: "
        if is_string?(-1)
          str << to_string(-1)
          pop(1)
        else
          str << "Unknown"
        end
        str << '\n'
      end
    end

    ### ERROR FUNCTIONS

    # Lua: `luaL_argerror`
    def raise_arg_error(pos : Int32, reason : String)
      if ar = get_stack(0)
        if get_info("n", ar)
          if ar.name_type.method?
            pos -= 1 # do not count `self`
            if pos == 0 # error is in the self argument itself?
              raise LuaArgumentError.new("calling '#{ar.name}' on bad self (#{reason})")
            end
          end
        end
        raise LuaArgumentError.new("bad argument ##{pos} to '#{ar.name || "?"}' (#{reason})")
      else # no stack frame?
        raise LuaArgumentError.new("bad argument ##{pos} to (#{reason})")
      end
    end

    # Lua: `luaL_typerror`
    def raise_type_error(pos : Int32, type : String)
      raise_arg_error(pos, "'#{type}' expected, got '#{type_name_at(pos)}'")
    end

    # Lua: `luaL_checkany`
    def assert_any?(index : Int32) : Nil
      if is_none?(index)
        raise_arg_error(index, "value expected")
      end
    end

    # Lua: `luaL_checkinteger`
    def assert_integer?(index : Int32) : Nil
      if to_i64(index) == 0 && !is_number?(index) # avoid extra test when not 0
        raise_type_error(index, type_name(:number))
      end
    end

    # Lua: `luaL_checklstring`
    def assert_string?(index : Int32, size : UInt64) : Nil
      unless LibLuaJIT.lua_tolstring(self, index, pointerof(size))
        raise_type_error(index, type_name(:string))
      end
    end

    # Lua: `luaL_checkstring`
    def assert_string?(index : Int32) : Nil
      unless LibLuaJIT.lua_tolstring(self, index, nil)
        raise_type_error(index, type_name(:string))
      end
    end

    # Lua: `luaL_checknumber`
    def assert_number?(index : Int32) : Nil
      if to_f64(index) == 0 && !is_number?(index) # avoid extra test when not 0
        raise_type_error(index, type_name(:number))
      end
    end

    # Lua: `luaL_checktype`
    def assert_type?(index : Int32, type : LuaType) : Nil
      unless get_type(index) == type
        raise_type_error(index, type_name(type))
      end
    end

    def assert_nil?(index : Int32) : Nil
      assert_type?(index, :nil)
    end

    def assert_bool?(index : Int32) : Nil
      assert_type?(index, :boolean)
    end

    def assert_light_userdata?(index : Int32) : Nil
      assert_type?(index, :light_userdata)
    end

    def assert_table?(index : Int32) : Nil
      assert_type?(index, :table)
    end

    def assert_function?(index : Int32) : Nil
      assert_type?(index, :function)
    end

    def assert_thread?(index : Int32) : Nil
      assert_type?(index, :thread)
    end

    def assert_userdata?(index : Int32) : Nil
      assert_type?(index, :userdata)
    end

    # Lua: `luaL_checkudata`
    def check_userdata?(index : Int32, type : String) : Nil
      if to_userdata?(index) # value is a userdata?
        if get_metatable(index) # does it have a metatable?
          get_registry!(type) # get correct metatable
          if raw_eq(-1, -2) # does it have correct mt?
            pop(2) # remove both metatables
            return
          end
        end
      end
      raise_type_error(index, type) # else error
    end

    def create_userdata(value : U) : Nil forall U
      # create box
      box = Box(U).box(value)
      # track box
      track(box)
      # create userdata
      ud_size = sizeof(Box(U)).to_u64
      ud_ptr = new_userdata(ud_size).as(Pointer(typeof(box)))
      ud_ptr.value = box
      # create metatable
      new_metatable(LuaState.metatable_name({{ U.name.stringify }}))
      # set copy of metatable
      push_value(-1)
      set_metatable(-3)
      # define metamethods for metatable
      push("__gc")
      push do |s|
        s.untrack(box)
        0
      end
      raw_set(-3)
      pop(1)
    end

    def get_userdata(_type : U.class, index : Int32) : U forall U
      ud_ptr = get_raw_userdata(U, index).as(Pointer(Pointer(Void)))
      Box(U).unbox(ud_ptr.value)
    end

    def get_raw_userdata(_type : U.class, index : Int32) : Pointer(Void) forall U
      mt_name = LuaState.metatable_name({{ U.name.stringify }})
      check_userdata?(index, mt_name)
      to_userdata!(index)
    end

    ### REFERENCE FUNCTIONS

    # Lua: `luaL_ref`, `[-1, +0, m]`
    def ref(index : Int32) : Int32
      LibLuaJIT.luaL_ref(self, index)
    end

    # Lua: `luaL_unref`, `[-0, +0, -]`
    def unref(index : Int32, ref : Int32) : Nil
      LibLuaJIT.luaL_unref(self, index, ref)
    end

    def create_ref : LuaRef
      type = get_type(-1)
      ref_id = ref(LibLuaJIT::LUA_REGISTRYINDEX)
      if ref_id == LibLuaJIT::LUA_REFNIL
        raise LuaArgumentError.new("value at top of stack was 'nil'")
      elsif ref_id == LibLuaJIT::LUA_NOREF
        raise LuaArgumentError.new("ref cannot be created")
      end
      LuaRef.new(ref_id, type)
    end

    def remove_ref(r : LuaRef) : Nil
      unref(LibLuaJIT::LUA_REGISTRYINDEX, r.ref)
    end

    def remove_ref(any : LuaAny) : Nil
      if r = any.as_ref?
        remove_ref(r)
      end
    end

    def remove_refs(hash : Hash(String | Float64, LuaAny)) : Nil
      hash.values.each do |any|
        remove_ref(any)
      end
    end

    def get_ref_value(r : LuaRef) : Nil
      raw_get_index(LibLuaJIT::LUA_REGISTRYINDEX, r.ref)
    end

    def ref_to_h(r : LuaRef) : Hash(String | Float64, LuaAny)
      get_ref_value(r)
      to_h(-1)
    end

    ### TRACKING FUNCTIONS

    # Add pointer to be tracked by Crystal
    def track(ptr : Pointer(Void)) : Nil
      Trackable.track(get_registry_address, ptr)
    end

    # Remove pointer tracked by Crystal
    def untrack(ptr : Pointer(Void)) : Nil
      Trackable.untrack(get_registry_address, ptr)
    end

    ### WRAPPER FUNCTIONS

    def to_any?(index : Int32) : LuaAny?
      case type = get_type(index)
      when .number?
        LuaAny.new(to_f(index))
      when .boolean?
        LuaAny.new(to_boolean(index))
      when .string?
        LuaAny.new(to_string(index))
      when .light_userdata?, .function?, .userdata?, .thread?, .table?
        push_value(index)
        LuaAny.new(create_ref)
      else
        nil
      end
    end

    def to_h(index : Int32) : Hash(String | Float64, LuaAny)
      push_value(index)
      LuaTableIterator.new(self).to_h.tap do
        pop(1)
      end
    end

    def to_a(index : Int32) : Array(LuaAny)
      hash = to_h(index)
      total = hash.keys.count { |k| k.is_a?(Float64) && k > 0 && k % 1 == 0 }
      Array(LuaAny).new(total).tap do |arr|
        total.times do |n|
          i = n + 1
          if value = hash[i]?
            arr << value
          else
            break
          end
        end
      end
    end
  end
end
