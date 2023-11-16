module Luajit
  struct LuaState
    alias CFunction = LibLuaJIT::CFunction
    alias Function = LuaState -> Int32
    alias Debug = LibLuaJIT::Debug

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
      state.set_registry(MT_NAME)
    end

    def self.new_state : LuaState
      state = new(LibLuaJIT.luaL_newstate)
      set_registry_address(state)
      state.at_panic do |l|
        STDERR.puts LuaError.new(LuaState.new(l)).to_s
        0
      end
      state
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
      get_registry(MT_NAME)
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
    LUA_EQUAL_PROC = CFunction.new do |l|
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
    # Lua: `lua_equal`, `[-0, +0, e]`
    def eq(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_pushcclosure(self, LUA_EQUAL_PROC, 0)
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

    # Returns `true` if the two values in indices *index1* and *index2* are primitively equal
    #
    # Does not call metamethods
    #
    # Lua: `lua_rawequal`, `[-0, +0, -]`
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

    # Returns `true` if the value at *index1* is smaller than the value at *index2*
    #
    # Follows the semantics of the Lua `<` operator (i.e. may call metamethods)
    #
    # Lua: `lua_lessthan`, `[-0, +0, e]`
    def less_than(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_pushcclosure(self, LUA_LESSTHAN_PROC, 0)
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
    def to_c_function?(index : Int32) : CFunction?
      proc = LibLuaJIT.lua_tocfunction(self, index)
      if proc.pointer
        proc
      end
    end

    # :ditto:
    def to_c_function!(index : Int32) : CFunction
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
      LibLuaJIT.lua_remove(self, index)
    end

    # Lua: `lua_insert`, `[-1, +1, -]`
    def insert(index : Int32) : Nil
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
    def get_stack(level : Int32) : Debug?
      if LibLuaJIT.lua_getstack(self, level, out ar) == true.to_unsafe
        ar
      end
    end

    # Lua: `lua_getinfo`, `[-(0|1), +(0|1|2), m]`
    def get_info(what : String, ar : Debug) : Debug?
      if LibLuaJIT.lua_getinfo(self, what, pointerof(ar)) != 0
        ar
      end
    end

    # Lua: `lua_getlocal`, `[-0, +(0|1), -]`
    def get_local(ar : Debug, n : Int32 = 1) : String?
      if ptr = LibLuaJIT.lua_getlocal(self, pointerof(ar), n)
        String.new(ptr)
      end
    end

    # Lua: `lua_setlocal`, `[-(0|1), +0, -]`
    def set_local(ar : Debug, n : Int32 = 1) : String?
      if ptr = LibLuaJIT.lua_setlocal(self, pointerof(ar), n)
        String.new(ptr)
      end
    end

    # Lua: `lua_getupvalue`, `[-0, +(0|1), -]`
    def get_up_value(fn_index : Int32, n : Int32) : String?
      if ptr = LibLuaJIT.lua_getupvalue(self, fn_index, n)
        String.new(ptr)
      end
    end

    # Lua: `lua_upvalueindex`
    def up_value(index : Int32) : Int32
      LibLuaJIT::LUA_GLOBALSINDEX - index
    end

    # Lua: `lua_setupvalue`, `[-(0|1), +0, -]`
    def set_up_value(fn_index : Int32, n : Int32) : String?
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
    def print_stack : Nil
      count = -1
      size.downto(1) do |index|
        puts "(#{count}) [#{index}]: #{get_type(index)}"
        count -= 1
      end
    end

    ### GC FUNCTIONS

    # Lua: `lua_gc`, `[-0, +0, e]`
    def gc : LuaGC
      LuaGC.new(self)
    end

    ### GET FUNCTIONS

    # :nodoc:
    LUA_GETTABLE_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      index = state.to_i(-1)
      LibLuaJIT.lua_gettable(state, index)
      1
    end

    # Lua: `lua_gettable`, `[-1, +1, e]`
    def get_table(index : Int32) : Nil
      LibLuaJIT.lua_pushcclosure(self, LUA_GETTABLE_PROC, 0)
      push(index)
      status = pcall(1, 1)
      unless status.ok?
        raise LuaAPIError.new
      end
    end

    # :nodoc:
    LUA_GETFIELD_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      state.pop(1)
      LibLuaJIT.lua_getfield(state, -1, key)
      1
    end

    # Lua: `lua_getfield`, `[-0, +1, e]`
    def get_field(index : Int32, name : String) : Nil
      case index
      when LibLuaJIT::LUA_GLOBALSINDEX
        return get_global(name)
      when LibLuaJIT::LUA_REGISTRYINDEX
        return get_registry(name)
      when LibLuaJIT::LUA_ENVIRONINDEX
        return get_environment(name)
      end

      push_value(index)
      LibLuaJIT.lua_pushcclosure(self, LUA_GETFIELD_PROC, 0)
      insert(-2)
      push(name)
      status = pcall(2, 1)
      unless status.ok?
        raise LuaAPIError.new
      end
    end

    # :nodoc:
    LUA_GETGLOBAL_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      LibLuaJIT.lua_getfield(state, LibLuaJIT::LUA_GLOBALSINDEX, key)
      1
    end

    def get_global(name : String) : Nil
      LibLuaJIT.lua_pushcclosure(self, LUA_GETGLOBAL_PROC, 0)
      push(name)
      status = pcall(1, 1)
      unless status.ok?
        raise LuaAPIError.new
      end
    end

    # :nodoc:
    LUA_GETREGISTRY_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      LibLuaJIT.lua_getfield(state, LibLuaJIT::LUA_REGISTRYINDEX, key)
      1
    end

    def get_registry(name : String) : Nil
      LibLuaJIT.lua_pushcclosure(self, LUA_GETREGISTRY_PROC, 0)
      push(name)
      status = pcall(1, 1)
      unless status.ok?
        raise LuaAPIError.new
      end
    end

    # Lua: `luaL_getmetatable`, `[-0, +1, -]`
    def get_metatable(tname : String) : Nil
      get_registry(tname)
    end

    # :nodoc:
    LUA_GETENVIRONMENT_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      key = state.to_string(-1)
      LibLuaJIT.lua_getfield(state, LibLuaJIT::LUA_ENVIRONINDEX, key)
      1
    end

    def get_environment(name : String) : Nil
      LibLuaJIT.lua_pushcclosure(self, LUA_GETENVIRONMENT_PROC, 0)
      push(name)
      status = pcall(1, 1)
      unless status.ok?
        raise LuaAPIError.new
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
      LuaStatus.new(LibLuaJIT.lua_pcall(self, nargs, nresults, errfunc))
    end

    # Lua: `lua_cpcall`, `[-0, +(0|1), -]`
    def c_pcall(&block : Function) : LuaStatus
      box = Box(typeof(block)).box(block)
      proc = CFunction.new do |l|
        state = LuaState.new(l)
        if ud = state.to_userdata?(-1)
          state.pop(1)
          begin
            Box(typeof(block)).unbox(ud).call(state)
          rescue err
            LibLuaJIT.luaL_error(state, err.to_s)
          end
        else
          LibLuaJIT.luaL_error(state, "UserData not found")
        end
      end
      LuaStatus.new(LibLuaJIT.lua_cpcall(self, proc, box))
    end

    # Lua: `luaL_dostring`, `[-0, +?, m]`
    def execute(str : String) : LuaStatus
      status = LuaStatus.new(LibLuaJIT.luaL_loadstring(self, str))
      return pcall(0, LibLuaJIT::LUA_MULTRET) if status.ok?
      status
    end

    # Lua: `luaL_dofile`, `[-0, +?, m]`
    def execute(path : Path) : LuaStatus
      status = LuaStatus.new(LibLuaJIT.luaL_loadfile(self, path.to_s))
      return pcall(0, LibLuaJIT::LUA_MULTRET) if status.ok?
      status
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

    # Lua: `lua_next`, `[-1, +(2|0), e]`
    def next(index : Int32) : Bool
      push_value(index)
      insert(-2)
      LibLuaJIT.lua_pushcclosure(self, LUA_NEXT_PROC, 0)
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

    # Lua: `lua_concat`, `[-n, +1, e]`
    def concat(n : Int32) : Nil
      if n < 1
        return push("")
      elsif n == 1
        return
      end

      LibLuaJIT.lua_pushcclosure(self, LUA_CONCAT_PROC, 0)
      insert(-(n) - 1)
      status = pcall(n, 1)
      unless status.ok?
        raise LuaAPIError.new
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

    # Lua: `lua_pushcclosure`, `[-n, +1, m]`
    def push(&block : Function) : Nil
      box = Box(typeof(block)).box(block)
      track(box)
      proc = CFunction.new do |l|
        state = LuaState.new(l)
        if ud = state.to_userdata?(state.up_value(1))
          state.pop(1)
          begin
            Box(typeof(block)).unbox(ud).call(state)
          rescue err
            LibLuaJIT.luaL_error(state, err.inspect)
          end
        else
          LibLuaJIT.luaL_error(state, "UserData not found")
        end
      end
      push(box)
      LibLuaJIT.lua_pushcclosure(self, proc, 1)
    end

    # Lua: `lua_pushboolean`, `[-0, +1, -]`
    def push(x : Bool) : Nil
      LibLuaJIT.lua_pushboolean(self, x)
    end

    # Lua: `lua_pushlightuserdata`, `[-0, +1, -]`
    def push(x : Pointer(Void)) : Nil
      LibLuaJIT.lua_pushlightuserdata(self, x)
    end

    # Lua: `lua_pushthread`, `[-0, +1, -]`
    def push_thread(x : LuaState) : ThreadStatus
      if LibLuaJIT.lua_pushthread(x) == 1
        ThreadStatus::Main
      else
        ThreadStatus::Coroutine
      end
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

    ### SET FUNCTIONS

    # :nodoc:
    LUA_SETTABLE_PROC = CFunction.new do |l|
      state = LuaState.new(l)
      LibLuaJIT.lua_settable(state, -3)
      0
    end

    # Lua: `lua_settable`, `[-2, +0, e]`
    def set_table(index : Int32) : Nil
      push_value(index)
      insert(-3)
      LibLuaJIT.lua_pushcclosure(self, LUA_SETTABLE_PROC, 0)
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

    # Lua: `lua_setfield`, `[-1, +0, e]`
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
      LibLuaJIT.lua_pushcclosure(self, LUA_SETFIELD_PROC, 0)
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

    # Lua: `lua_setglobal`, `[-1, +0, e]`
    def set_global(name : String) : Nil
      LibLuaJIT.lua_pushcclosure(self, LUA_SETGLOBAL_PROC, 0)
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

    def set_registry(name : String) : Nil
      LibLuaJIT.lua_pushcclosure(self, LUA_SETREGISTRY_PROC, 0)
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

    def set_environment(name : String) : Nil
      LibLuaJIT.lua_pushcclosure(self, LUA_SETENVIRONMENT_PROC, 0)
      insert(-2)
      push(name)
      status = pcall(2, 0)
      unless status.ok?
        raise LuaAPIError.new
      end
    end

    # Lua: `lua_register`
    def register_global(name : String, &block : Function) : Nil
      push(&block)
      set_global(name)
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

    # Lua: `luaL_callmeta`, `[-0, +(0|1), e]`
    def call_metamethod(obj : Int32, event : String) : Bool
      obj = abs_index(obj)
      if get_metafield(obj, event)
        push_value(obj)
        raise LuaAPIError.new unless pcall(1, 1).ok?
        true
      else
        false
      end
    end

    private def abs_index(i : Int32) : Int32
      if i > 0 || i <= LibLuaJIT::LUA_REGISTRYINDEX
        i
      else
        size + i + 1
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
    def at_panic(&cb : CFunction) : CFunction
      LibLuaJIT.lua_atpanic(self, cb)
    end

    ### ERROR FUNCTIONS

    # Lua: `luaL_argerror`
    def raise_arg_error(pos : Int32, reason : String)
      if ar = get_stack(0)
        if ar = get_info("n", ar)
          if String.new(ar.namewhat || Bytes[]) == "method"
            pos -= 1 # do not count `self`
            if pos == 0 # error is in the self argument itself?
              raise "calling '#{String.new(ar.name || Bytes[])}' on bad self (#{reason})"
            end
          end
        end
        raise "bad argument ##{pos} to '#{String.new(ar.name || "?".to_slice)}' (#{reason})"
      else # no stack frame?
        raise "bad argument ##{pos} (#{reason})"
      end
    end

    # Lua: `luaL_typerror`
    def raise_type_error(pos : Int32, type : String)
      raise_arg_error(pos, "#{type} expected, got #{type_name_at(pos)}")
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

    # Lua: `luaL_checkudata`
    def assert_userdata?(index : Int32, type : String) : Nil
      if to_userdata?(index) # value is a userdata?
        if get_metatable(index) # does it have a metatable?
          get_registry(type) # get correct metatable
          if raw_eq(-1, -2) # does it have correct mt?
            pop(2) # remove both metatables
            return
          end
        end
      end
      raise_type_error(index, type) # else error
    end

    def assert_userdata?(index : Int32) : Nil
      assert_type?(index, :userdata)
    end

    ### REFERENCE FUNCTIONS

    # Lua: `luaL_ref`, `[-1, +0, m]`
    def create_ref(index : Int32) : Int32
      LibLuaJIT.luaL_ref(self, index)
    end

    # Lua: `luaL_unref`, `[-0, +0, -]`
    def remove_ref(index : Int32, ref : Int32) : Nil
      LibLuaJIT.luaL_unref(self, index, ref)
    end

    def create_registry_ref : Int32
      create_ref(LibLuaJIT::LUA_REGISTRYINDEX)
    end

    def remove_registry_ref(ref : Int32) : Nil
      remove_ref(LibLuaJIT::LUA_REGISTRYINDEX, ref)
    end

    def get_registry_ref(ref : Int32) : Nil
      raw_get_index(LibLuaJIT::LUA_REGISTRYINDEX, ref)
    end

    ### TRACKING FUNCTIONS

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

    ### WRAPPER FUNCTIONS

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
  end
end
