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

    def self.create : LuaState
      new(LibLuaJIT.luaL_newstate).tap do |state|
        state.at_panic do |l|
          STDERR.puts LuaState.new(l).at_panic_default_error_message
          0
        end
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

    # Returns `true` if value at the given *index* has type boolean
    #
    # Lua: `lua_isboolean`
    def is_bool?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TBOOLEAN
    end

    # Returns `true` if value at the given *index* is a number or a string convertible to a number
    #
    # Lua: `lua_isnumber`
    def is_number?(index : Int32) : Bool
      LibLuaJIT.lua_isnumber(self, index) == true.to_unsafe
    end

    # Returns `true` if value at the given *index* is a string or a number (which is always convertible to a string)
    #
    # Lua: `lua_isstring`
    def is_string?(index : Int32) : Bool
      LibLuaJIT.lua_isstring(self, index) == true.to_unsafe
    end

    # Returns `true` if value at the given *index* is a function (either C or Lua)
    #
    # Lua: `lua_isfunction`
    def is_function?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TFUNCTION
    end

    # Returns `true` if value at the given *index* is a C function
    #
    # Lua: `lua_iscfunction`
    def is_c_function?(index : Int32) : Bool
      LibLuaJIT.lua_iscfunction(self, index) == true.to_unsafe
    end

    # Returns `true` if value at the given *index* is a userdata (either full or light)
    #
    # Lua: `lua_isuserdata`
    def is_userdata?(index : Int32) : Bool
      LibLuaJIT.lua_isuserdata(self, index) == true.to_unsafe
    end

    # Returns `true` if value at the given *index* is a light userdata
    #
    # Lua: `lua_islightuserdata`
    def is_light_userdata?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TLIGHTUSERDATA
    end

    # Returns `true` if value at the given *index* is a thread
    #
    # Lua: `lua_isthread`
    def is_thread?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TTHREAD
    end

    # Returns `true` if value at the given *index* is a table
    #
    # Lua: `lua_istable`
    def is_table?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TTABLE
    end

    # Returns `true` if value at the given *index* is nil
    #
    # Lua: `lua_isnil`
    def is_nil?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TNIL
    end

    # Returns `true` if value at the given *index* is not valid (refers to an element outside the current stack)
    #
    # Lua: `lua_isnone`
    def is_none?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TNONE
    end

    # Returns `true` if value at the given *index* is not valid (refers to an element outside the current stack) or is nil
    #
    # Lua: `lua_isnoneornil`
    def is_none_or_nil?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) <= 0
    end

    # Returns the type of the value at the given *index*
    #
    # Lua: `lua_type`
    def get_type(index : Int32) : LuaType
      LuaType.new(LibLuaJIT.lua_type(self, index))
    end

    # Returns the name of the *lua_type* value
    #
    # Lua: `lua_typename`
    def type_name(lua_type : LuaType) : String
      String.new(LibLuaJIT.lua_typename(self, lua_type.value) || Bytes[])
    end

    # Returns the name of the type of the value at the given *index*
    #
    # Lua: `luaL_typename`
    def type_name_at(index : Int32) : String
      String.new(LibLuaJIT.lua_typename(self, LibLuaJIT.lua_type(self, index)) || Bytes[])
    end

    # Returns `true` if the two values in indices *index1* and *index2* are equal
    #
    # Follows the semantics of the Lua `==` operator (i.e. may call metamethods)
    #
    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_equal`
    def eq!(index1 : Int32, index2 : Int32) : Bool
      index1 = abs_index(index1)
      index2 = abs_index(index2)
      push_value(index1)
      push_value(index2)
      push_fn do |l|
        s = LuaState.new(l)
        s.push(LibLuaJIT.lua_equal(s, -2, -1) == true.to_unsafe)
        1
      end
      insert(-3)
      pcall!(2, 1, err_msg: "lua_equal")
      to_boolean(-1).tap do
        pop(1)
      end
    end

    # Returns `true` if the two values in indices *index1* and *index2* are primitively equal
    #
    # Does not call metamethods
    #
    # Lua: `lua_rawequal`
    def raw_eq(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_rawequal(self, index1, index2) == true.to_unsafe
    end

    # Returns `true` if the value at *index1* is smaller than the value at *index2*
    #
    # Follows the semantics of the Lua `<` operator (i.e. may call metamethods)
    #
    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_lessthan`
    def less_than!(index1 : Int32, index2 : Int32) : Bool
      index1 = abs_index(index1)
      index2 = abs_index(index2)
      push_value(index1)
      push_value(index2)
      push_fn do |l|
        s = LuaState.new(l)
        s.push(LibLuaJIT.lua_lessthan(s, -2, -1) == true.to_unsafe)
        1
      end
      insert(-3)
      pcall!(2, 1, err_msg: "lua_lessthan")
      to_boolean(-1).tap do
        pop(1)
      end
    end

    # Converts the Lua value at *index* to `Float64`
    #
    # The value must be a number or a string convertible to a number, otherwise returns 0
    #
    # Lua: `lua_tonumber`
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
    # Lua: `lua_tointeger`
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
    # Lua: `lua_toboolean`
    def to_boolean(index : Int32) : Bool
      LibLuaJIT.lua_toboolean(self, index) == true.to_unsafe
    end

    # Lua: `lua_tolstring`
    def to_string(index : Int32, size : UInt64) : String
      String.new(LibLuaJIT.lua_tolstring(self, index, pointerof(size)) || Bytes[])
    end

    # Lua: `lua_tostring`
    def to_string(index : Int32) : String
      String.new(LibLuaJIT.lua_tolstring(self, index, nil) || Bytes[])
    end

    # Lua: `lua_objlen`
    def size_at(index : Int32) : UInt64
      LibLuaJIT.lua_objlen(self, index)
    end

    # Lua: `lua_tocfunction`
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

    # Lua: `lua_touserdata`
    def to_userdata?(index : Int32) : Pointer(Void)?
      if ptr = LibLuaJIT.lua_touserdata(self, index)
        ptr
      end
    end

    # :ditto:
    def to_userdata!(index : Int32) : Pointer(Void)
      to_userdata?(index).not_nil!
    end

    # Lua: `lua_tothread`
    def to_thread?(index : Int32) : LuaState?
      if ptr = LibLuaJIT.lua_tothread(self, index)
        LuaState.new(ptr)
      end
    end

    # :ditto:
    def to_thread!(index : Int32) : LuaState
      to_thread?(index).not_nil!
    end

    # Lua: `lua_topointer`
    def to_pointer?(index : Int32) : Pointer(Void)?
      if ptr = LibLuaJIT.lua_topointer(self, index)
        ptr
      end
    end

    # :ditto:
    def to_pointer!(index : Int32) : Pointer(Void)
      to_pointer?(index).not_nil!
    end

    # Lua: `lua_gettop`
    def size : Int32
      LibLuaJIT.lua_gettop(self)
    end

    # Lua: `lua_settop`
    def set_top(index : Int32) : Nil
      LibLuaJIT.lua_settop(self, index)
    end

    # Lua: `lua_pop`
    def pop(n : Int32) : Nil
      set_top(-(n) - 1)
    end

    # Lua: `lua_pushvalue`
    def push_value(index : Int32) : Nil
      LibLuaJIT.lua_pushvalue(self, index)
    end

    # Lua: `lua_remove`
    def remove(index : Int32) : Nil
      if is_pseudo(index)
        raise LuaArgumentError.new("cannot be called with a pseudo-index")
      end
      LibLuaJIT.lua_remove(self, index)
    end

    # Lua: `lua_insert`
    def insert(index : Int32) : Nil
      if is_pseudo(index)
        raise LuaArgumentError.new("cannot be called with a pseudo-index")
      end
      LibLuaJIT.lua_insert(self, index)
    end

    # Lua: `lua_replace`
    def replace(index : Int32) : Nil
      LibLuaJIT.lua_replace(self, index)
    end

    # Lua: `lua_xmove`
    def xmove(from : LuaState, to : LuaState, n : Int32) : Nil
      LibLuaJIT.lua_xmove(from, to, n)
    end

    # Lua: `lua_yield`
    def co_yield(nresults : Int32) : Int32
      LibLuaJIT.lua_yield(self, nresults)
    end

    # Lua: `lua_resume`
    def co_resume(narg : Int32) : Int32
      LibLuaJIT.lua_resume(self, narg)
    end

    # Lua: `lua_status`
    def status : LuaStatus
      LuaStatus.new(LibLuaJIT.lua_status(self))
    end

    # Lua: `lua_getstack`
    def get_stack(level : Int32) : LuaDebug?
      if LibLuaJIT.lua_getstack(self, level, out ar) == true.to_unsafe
        LuaDebug.new(ar)
      end
    end

    # Lua: `lua_getinfo`
    def get_info(what : String, ar : LuaDebug) : LuaDebug?
      if LibLuaJIT.lua_getinfo(self, what, ar) != 0
        ar
      end
    end

    # Lua: `lua_getlocal`
    def get_local(ar : LuaDebug, n : Int32 = 1) : String?
      if ptr = LibLuaJIT.lua_getlocal(self, ar, n)
        String.new(ptr)
      end
    end

    # Lua: `lua_setlocal`
    def set_local(ar : LuaDebug, n : Int32 = 1) : String?
      if ptr = LibLuaJIT.lua_setlocal(self, ar, n)
        String.new(ptr)
      end
    end

    # Lua: `lua_getupvalue`
    def get_upvalue(fn_index : Int32, n : Int32) : String?
      if ptr = LibLuaJIT.lua_getupvalue(self, fn_index, n)
        String.new(ptr)
      end
    end

    # Lua: `lua_upvalueindex`
    def upvalue(index : Int32) : Int32
      LibLuaJIT::LUA_GLOBALSINDEX - index
    end

    # Lua: `lua_setupvalue`
    def set_upvalue(fn_index : Int32, n : Int32) : String?
      if ptr = LibLuaJIT.lua_setupvalue(self, fn_index, n)
        String.new(ptr)
      end
    end

    # Lua: `lua_sethook`
    def set_hook(f : LibLuaJIT::Hook, mask : Int32, count : Int32) : Nil
      LibLuaJIT.lua_sethook(self, f, mask, count)
    end

    # Lua: `lua_gethook`
    def get_hook : LibLuaJIT::Hook
      LibLuaJIT.lua_gethook(self)
    end

    # Lua: `lua_gethookmask`
    def get_hook_mask : Int32
      LibLuaJIT.lua_gethookmask(self)
    end

    # Lua: `lua_gethookcount`
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

    # Lua: `lua_gc`
    def gc : LuaGC
      LuaGC.new(self)
    end

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_gettable`
    def get_table!(index : Int32) : Nil
      push_value(index)
      insert(-2)
      push_fn do |l|
        LibLuaJIT.lua_gettable(l, -2)
        1
      end
      insert(-3)
      pcall!(2, 1, err_msg: "lua_gettable")
    end

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_getfield`
    def get_field!(index : Int32, name : String) : Nil
      return get_global!(name) if index == LibLuaJIT::LUA_GLOBALSINDEX
      return get_registry!(name) if index == LibLuaJIT::LUA_REGISTRYINDEX
      return get_environment!(name) if index == LibLuaJIT::LUA_ENVIRONINDEX

      push_value(index)
      push_fn do |l|
        s = LuaState.new(l)
        k = s.to_string(-1)
        s.pop(1)
        LibLuaJIT.lua_getfield(s, -1, k)
        1
      end
      insert(-2)
      push(name)
      pcall!(2, 1, err_msg: "lua_getfield")
    end

    # Raises `LuaProtectedError` if underlying operation failed
    def get_global!(name : String) : Nil
      push_fn do |l|
        s = LuaState.new(l)
        k = s.to_string(-1)
        LibLuaJIT.lua_getfield(s, LibLuaJIT::LUA_GLOBALSINDEX, k)
        1
      end
      push(name)
      pcall!(1, 1, err_msg: "LuaState#get_global!")
    end

    # Raises `LuaProtectedError` if underlying operation failed
    def get_registry!(name : String) : Nil
      push_fn do |l|
        s = LuaState.new(l)
        k = s.to_string(-1)
        LibLuaJIT.lua_getfield(s, LibLuaJIT::LUA_REGISTRYINDEX, k)
        1
      end
      push(name)
      pcall!(1, 1, err_msg: "LuaState#get_registry!")
    end

    # Lua: `luaL_getmetatable`
    def get_metatable(tname : String) : Nil
      get_registry!(tname)
    end

    # Raises `LuaProtectedError` if underlying operation failed
    def get_environment!(name : String) : Nil
      push_fn do |l|
        s = LuaState.new(l)
        k = s.to_string(-1)
        LibLuaJIT.lua_getfield(s, LibLuaJIT::LUA_ENVIRONINDEX, k)
        1
      end
      push(name)
      pcall!(1, 1, err_msg: "LuaState#get_environment!")
    end

    # Lua: `lua_rawget`
    def raw_get(index : Int32) : Nil
      LibLuaJIT.lua_rawget(self, index)
    end

    # Lua: `lua_rawgeti`
    def raw_get_index(index : Int32, n : Int32) : Nil
      LibLuaJIT.lua_rawgeti(self, index, n)
    end

    # Lua: `lua_createtable`
    def create_table(narr : Int32, nrec : Int32) : Nil
      LibLuaJIT.lua_createtable(self, narr, nrec)
    end

    # Lua: `lua_newtable`
    def new_table : Nil
      create_table(0, 0)
    end

    # Lua: `lua_newuserdata`
    def new_userdata(size : UInt64) : Pointer(Void)
      LibLuaJIT.lua_newuserdata(self, size)
    end

    # Lua: `lua_getmetatable`
    def get_metatable(index : Int32) : Bool
      LibLuaJIT.lua_getmetatable(self, index) != 0
    end

    # Lua: `lua_getfenv`
    def get_fenv(index : Int32) : Nil
      LibLuaJIT.lua_getfenv(self, index)
    end

    # Lua: `lua_pcall`
    def pcall(nargs : Int32, nresults : Int32, errfunc : Int32 = 0) : LuaStatus
      if is_pseudo(errfunc)
        raise LuaArgumentError.new("'errfunc' argument cannot be a pseudo-index")
      end
      LuaStatus.new(LibLuaJIT.lua_pcall(self, nargs, nresults, errfunc))
    end

    def pcall!(nargs : Int32, nresults : Int32, err_msg : String) : Nil
      pcall(nargs, nresults).tap do |status|
        unless status.ok?
          raise LuaProtectedError.new(self, status, err_msg)
        end
      end
    end

    # Lua Compat 5.3
    def c_pcall(&block : Function) : LuaStatus
      push(block)
      pcall(0, 0)
    end

    # Lua: `luaL_dostring`
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

    # Lua: `luaL_dofile`
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

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_next`
    def next!(index : Int32) : Bool
      push_value(index)
      insert(-2)
      push_fn do |l|
        s = LuaState.new(l)
        r = LibLuaJIT.lua_next(s, -2)
        if r != 0
          s.push(true)
        else
          s.push(nil)
          s.push(nil)
          s.push(false)
        end
        3
      end
      insert(-3)
      pcall!(2, 3, err_msg: "lua_next")
      to_boolean(-1).tap do |result|
        pop(1)
        pop(2) unless result
      end
    end

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_concat`
    def concat!(n : Int32) : Nil
      if n < 1
        push("")
        return
      elsif n == 1
        return
      end

      push_fn do |l|
        LibLuaJIT.lua_concat(l, LuaState.new(l).size)
        1
      end
      insert(-(n) - 1)
      pcall!(n, 1, err_msg: "lua_concat")
    end

    # Lua: `lua_pushnil`
    def push(_x : Nil) : Nil
      LibLuaJIT.lua_pushnil(self)
    end

    # Lua: `lua_pushnumber`
    def push(x : Float64) : Nil
      LibLuaJIT.lua_pushnumber(self, x)
    end

    def push(x : Float32) : Nil
      push(x.to_f64)
    end

    # Lua: `lua_pushinteger`
    def push(x : Int64) : Nil
      LibLuaJIT.lua_pushinteger(self, x)
    end

    def push(x : Int32) : Nil
      push(x.to_i64)
    end

    # Lua: `lua_pushstring`
    def push(x : String) : Nil
      LibLuaJIT.lua_pushstring(self, x)
    end

    def push(x : Char) : Nil
      push(x.to_s)
    end

    def push(x : Symbol) : Nil
      push(x.to_s)
    end

    # Lua: `lua_pushcfunction`
    def push(x : LuaCFunction) : Nil
      LibLuaJIT.lua_pushcclosure(self, x, 0)
    end

    # Lua: `lua_pushcclosure`
    def push(x : Function) : Nil
      push_fn_closure do |state|
        x.call(state)
      end
    end

    # Lua: `lua_pushboolean`
    def push(x : Bool) : Nil
      LibLuaJIT.lua_pushboolean(self, x)
    end

    # Lua: `lua_pushlightuserdata`
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

    # Lua: `lua_pushcfunction`
    def push_fn(&block : LuaCFunction) : Nil
      push(block)
    end

    # Lua: `lua_pushcclosure`
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

    # Lua: `lua_pushthread`
    def push_thread(x : LuaState) : ThreadStatus
      if LibLuaJIT.lua_pushthread(x) == 1
        ThreadStatus::Main
      else
        ThreadStatus::Coroutine
      end
    end

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_settable`
    def set_table!(index : Int32) : Nil
      push_value(index)
      insert(-3)
      push_fn do |l|
        LibLuaJIT.lua_settable(l, -3)
        0
      end
      insert(-4)
      pcall!(3, 0, err_msg: "lua_settable")
    end

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_setfield`
    def set_field!(index : Int32, k : String) : Nil
      return set_global!(k) if index == LibLuaJIT::LUA_GLOBALSINDEX
      return set_registry!(k) if index == LibLuaJIT::LUA_REGISTRYINDEX
      return set_environment!(k) if index == LibLuaJIT::LUA_ENVIRONINDEX

      push_value(index)
      insert(-2)
      push_fn do |l|
        s = LuaState.new(l)
        k = s.to_string(-1)
        s.pop(1)
        LibLuaJIT.lua_setfield(s, -2, k)
        0
      end
      insert(-3)
      push(k)
      pcall!(3, 0, err_msg: "lua_setfield")
    end

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `lua_setglobal`
    def set_global!(name : String) : Nil
      push_fn do |l|
        s = LuaState.new(l)
        k = s.to_string(-1)
        s.pop(1)
        LibLuaJIT.lua_setfield(s, LibLuaJIT::LUA_GLOBALSINDEX, k)
        0
      end
      insert(-2)
      push(name)
      pcall!(2, 0, err_msg: "lua_setglobal")
    end

    # Raises `LuaProtectedError` if underlying operation failed
    def set_registry!(name : String) : Nil
      push_fn do |l|
        s = LuaState.new(l)
        k = s.to_string(-1)
        s.pop(1)
        LibLuaJIT.lua_setfield(s, LibLuaJIT::LUA_REGISTRYINDEX, k)
        0
      end
      insert(-2)
      push(name)
      pcall!(2, 0, err_msg: "LuaState#set_registry!")
    end

    # Raises `LuaProtectedError` if underlying operation failed
    def set_environment!(name : String) : Nil
      push_fn do |l|
        s = LuaState.new(l)
        k = s.to_string(-1)
        s.pop(1)
        LibLuaJIT.lua_setfield(s, LibLuaJIT::LUA_ENVIRONINDEX, k)
        0
      end
      insert(-2)
      push(name)
      pcall!(2, 0, err_msg: "LuaState#set_environment!")
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

    # Ensure that stack[idx][fname] has a table and push that table onto the stack
    #
    # Lua Compat 5.3
    def get_subtable(index : Int32, fname : String) : Bool
      get_field!(index, fname)
      if is_table?(-1)
        true
      else
        pop(1)
        index = abs_index(index)
        new_table
        push_value(-1)
        set_field!(index, fname)
        false
      end
    end

    # Stripped-down 'require': After checking "loaded" table, calls 'openf'
    # to open a module, registers the result in 'package.loaded' table and,
    # if 'glb' is true, also registers the result in the global table.
    # Leaves resulting module on the top.
    #
    # Lua Compat 5.3
    def requiref(modname : String, openf : LuaCFunction, glb : Bool = false) : Nil
      get_subtable("_LOADED")
      get_field!(-1, modname)
      unless to_boolean(-1)
        pop(1)
        push(openf)
        push(modname)
        pcall(1, 1)
        push_value(-1)
        set_field!(-3, modname)
      end
      remove(-2)
      if glb
        push_value(-1)
        set_global!(modname)
      end
    end

    # :nodoc:
    # TODO
    # - use `requiref` as baseline
    def register(l : Library) : Nil
      raise NotImplementedError.new("register(Library)")
    end

    # :nodoc:
    def register_library(name : String, & : Library ->) : Nil
      l = Library.new(name)
      yield l
      register(l)
    end

    # Lua: `luaL_register`
    def register(name : String, regs : Array(LuaReg)) : Nil
      libs = [] of LibLuaJIT::Reg
      regs.each do |reg|
        libs << LibLuaJIT::Reg.new(name: reg.name, func: reg.function.pointer)
      end
      libs << LibLuaJIT::Reg.new(name: Pointer(UInt8).null, func: Pointer(Void).null)
      LibLuaJIT.luaL_register(self, name, libs)
    end

    # Lua: `luaL_register`
    def register(regs : Array(LuaReg)) : Nil
      libs = [] of LibLuaJIT::Reg
      regs.each do |reg|
        libs << LibLuaJIT::Reg.new(name: reg.name, func: reg.function.pointer)
      end
      libs << LibLuaJIT::Reg.new(name: Pointer(UInt8).null, func: Pointer(Void).null)
      LibLuaJIT.luaL_register(self, Pointer(UInt8).null, libs)
    end

    # Lua: `lua_rawset`
    def raw_set(index : Int32) : Nil
      LibLuaJIT.lua_rawset(self, index)
    end

    # Lua: `lua_rawseti`
    def raw_set_index(index : Int32, n : Int32) : Nil
      LibLuaJIT.lua_rawseti(self, index, n)
    end

    # Lua: `lua_setmetatable`
    def set_metatable(index : Int32) : Int32
      LibLuaJIT.lua_setmetatable(self, index)
    end

    # Lua: `lua_setfenv`
    def set_fenv(index : Int32) : Int32
      LibLuaJIT.lua_setfenv(self, index)
    end

    # Lua: `luaL_newmetatable`
    def new_metatable(tname : String) : Bool
      LibLuaJIT.luaL_newmetatable(self, tname) != 0
    end

    # Lua: `luaL_getmetafield`
    def get_metafield(obj : Int32, e : String) : Bool
      LibLuaJIT.luaL_getmetafield(self, obj, e) != 0
    end

    # Raises `LuaProtectedError` if underlying operation failed
    #
    # Lua: `luaL_callmeta`
    def call_metamethod!(obj : Int32, event : String) : Bool
      obj = abs_index(obj)
      if get_metafield(obj, event)
        push_value(obj)
        pcall!(1, 1, err_msg: "LuaState#call_metamethod!")
        true
      else
        false
      end
    end

    # Lua Compat 5.3
    def abs_index(index : Int32) : Int32
      if index > 0 || is_pseudo(index)
        index
      else
        size + index + 1
      end
    end

    # :nodoc:
    def is_pseudo(index : Int32)
      index <= LibLuaJIT::LUA_REGISTRYINDEX
    end

    # Lua: `lua_close`
    def close : Nil
      LibLuaJIT.lua_close(self)
    end

    # Lua: `lua_newthread`
    def new_thread : LuaState
      LuaState.new(LibLuaJIT.lua_newthread(self))
    end

    # Lua: `lua_atpanic`
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

    # Lua: `luaL_argerror`
    def raise_arg_error(pos : Int32, reason : String)
      if ar = get_stack(0)
        if get_info("n", ar)
          if ar.name_type.method?
            pos -= 1    # do not count `self`
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
      if to_userdata?(index)    # value is a userdata?
        if get_metatable(index) # does it have a metatable?
          get_registry!(type)   # get correct metatable
          if raw_eq(-1, -2)     # does it have correct mt?
            pop(2)              # remove both metatables
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

    # Lua: `luaL_ref`
    def ref(index : Int32) : Int32
      LibLuaJIT.luaL_ref(self, index)
    end

    # Lua: `luaL_unref`
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

    # Add pointer to be tracked by Crystal
    def track(ptr : Pointer(Void)) : Nil
      Trackable.track(get_registry_address, ptr)
    end

    # Remove pointer tracked by Crystal
    def untrack(ptr : Pointer(Void)) : Nil
      Trackable.untrack(get_registry_address, ptr)
    end

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
