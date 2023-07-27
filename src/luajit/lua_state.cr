module Luajit
  struct LuaState
    alias CFunction = LibLuaJIT::CFunction
    alias Function = LuaState -> Int32
    alias Loader = LuaState, Pointer(UInt64) -> String?

    @ptr : Pointer(LibLuaJIT::State)

    def initialize(@ptr)
    end

    def to_unsafe
      @ptr
    end

    def version : Float64?
      if ptr = LibLuaJIT.lua_version(self)
        ptr.value
      end
    end

    def at_panic(&cb : CFunction) : CFunction
      LibLuaJIT.lua_atpanic(self, cb)
    end

    def call(num_args : Int32, num_results : Int32) : Nil
      LibLuaJIT.lua_call(self, num_args, num_results)
    end

    def concat(n : Int32) : Nil
      LibLuaJIT.lua_concat(self, n)
    end

    def c_pcall(&block : Function) : Int32
      box = Box(typeof(block)).box(block)
      proc = CFunction.new do |l|
        state = LuaState.new(l)
        ud = state.to_userdata(-1)
        Box(typeof(block)).unbox(ud).call(state)
      end
      LibLuaJIT.lua_cpcall(self, proc, box)
    end

    def size : Int32
      LibLuaJIT.lua_gettop(self)
    end

    def pop(n : Int32) : Nil
      LibLuaJIT.lua_settop(self, -(n) - 1)
    end

    def set_field(index : Int32, k : String) : Nil
      LibLuaJIT.lua_setfield(self, index, k)
    end

    def set_global(name : String) : Nil
      set_field(LibLuaJIT::LUA_GLOBALSINDEX, name)
    end

    def set_metatable(index : Int32) : Int32
      LibLuaJIT.lua_setmetatable(self, index)
    end

    def set_table(index : Int32) : Nil
      LibLuaJIT.lua_settable(self, index)
    end

    def get_field(index : Int32, name : String)
      LibLuaJIT.lua_getfield(self, index, name)
    end

    def get_global(name : String)
      get_field(LibLuaJIT::LUA_GLOBALSINDEX, name)
    end

    def to_boolean(index : Int32) : Bool
      LibLuaJIT.lua_toboolean(self, index) == true.to_unsafe
    end

    def to_i64(index : Int32) : Int64
      LibLuaJIT.lua_tointeger(self, index)
    end

    def to_string(index : Int32, size : UInt64) : String
      String.new(LibLuaJIT.lua_tolstring(self, index, pointerof(size)))
    end

    def to_string(index : Int32) : String
      String.new(LibLuaJIT.lua_tolstring(self, index, nil))
    end

    def to_f(index : Int32) : Float64
      LibLuajit.lua_tonumber(self, index)
    end

    def to_pointer(index : Int32) : Pointer(Void)
      LibLuaJIT.lua_topointer(self, index)
    end

    def to_userdata(index : Int32) : Pointer(Void)
      LibLuaJIT.lua_touserdata(self, index)
    end

    def <<(b : Bool) : self
      LibLuaJIT.lua_pushboolean(self, b)
      self
    end

    def <<(n : Int64) : self
      LibLuaJIT.lua_pushinteger(self, n)
      self
    end

    def <<(n : Int32) : self
      self << n.to_i64
    end

    def <<(ptr : Pointer(Void)) : self
      LibLuaJIT.lua_pushlightuserdata(self, ptr)
      self
    end

    def <<(_x : Nil) : self
      LibLuaJIT.lua_pushnil(self)
      self
    end

    def <<(n : Float64) : self
      LibLuaJIT.lua_pushnumber(self, n)
      self
    end

    def <<(str : String) : self
      LibLuaJIT.lua_pushstring(self, str)
      self
    end

    def <<(chr : Char) : self
      self << chr.to_s
    end

    def <<(sym : Symbol) : self
      self << sym.to_s
    end

    def <<(arr : Array) : self
      LibLuaJIT.createtable(self, arr.size, 0)
      arr.each_with_index do |item, index|
        self << index << item
        LibLuaJIT.settable(self, -3)
      end
      self
    end

    def <<(hash : Hash) : self
      LibLuaJIT.createtable(self, 0, hash.size)
      hash.each do |key, value|
        self << key << value
        LibLuaJIT.settable(self, -3)
      end
      self
    end

    def push_function(&block : Function) : Nil
      box = Box(typeof(block)).box(block)
      proc = CFunction.new do |l|
        state = LuaState.new(l)
        ud = state.to_userdata(state.upvalue_at(1))
        Box(typeof(block)).unbox(ud).call(state)
      end
      Luajit.pointers << box
      self << box
      LibLuaJIT.lua_pushcclosure(self, proc, 1)
    end

    def is?(lua_type : LuaType, index : Int32) : Bool
      case lua_type
      in .bool?
        LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TBOOLEAN
      in .number?
        LibLuaJIT.lua_isnumber(self, index) == 1
      in .string?
        LibLuaJIT.lua_isstring(self, index) == 1
      in .function?
        LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TFUNCTION
      in .c_function?
        LibLuaJIT.lua_iscfunction(self, index) == 1
      in .userdata?
        LibLuaJIT.lua_isuserdata(self, index) == 1
      in .light_userdata?
        LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TLIGHTUSERDATA
      in .thread?
        LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TTHREAD
      in .table?
        LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TTABLE
      in LuaType::Nil
        LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TNIL
      in .none?
        LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TNONE
      in .none_or_nil?
        LibLuaJIT.lua_type(self, index) <= 0
      end
    end

    def less_than(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_lessthan(self, index1, index2) == 1
    end

    def insert(index : Int32) : Nil
      LibLuaJIT.lua_insert(self, index)
    end

    def remove(index : Int32) : Nil
      LibLuaJIT.lua_remove(self, index)
    end

    def replace(index : Int32) : Nil
      LibLuaJIT.lua_replace(self, index)
    end

    def eq(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_equal(self, index1, index2) == true.to_unsafe
    end

    def next(index : Int32) : Bool
      LibLuaJIT.lua_next(self, index) == true.to_unsafe
    end

    def size_at(index : Int32) : UInt64
      LibLuaJIT.lua_objlen(self, index)
    end

    def push_value(index : Int32) : Nil
      LibLuaJIT.lua_pushvalue(self, index)
    end

    def raw_eq(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_rawequal(self, index1, index2) == true.to_unsafe
    end

    def raw_get(index : Int32) : Nil
      LibLuaJIT.lua_rawget(self, index)
    end

    def raw_geti(index : Int32, n : Int32) : Nil
      LibLuaJIT.lua_rawgeti(self, index, n)
    end

    def raw_set(index : Int32) : Nil
      LibLuaJIT.lua_rawset(self, index)
    end

    def raw_seti(index : Int32, n : Int32) : Nil
      LibLuaJIT.lua_rawseti(self, index, n)
    end

    def upvalue_at(index : Int32) : Int32
      LibLuaJIT::LUA_GLOBALSINDEX - index
    end

    def status
      case result = LibLuaJIT.lua_status(self)
      when LibLuaJIT::LUA_OK
        LuaStatus::Ok
      when LibLuaJIT::LUA_YIELD
        LuaStatus::Yield
      else
        LuaStatus.new(result)
      end
    end

    def load(chunk_name : String, &block : Loader) : Int32
      box = Box(typeof(cb)).box(block)
      proc = LibLuaJIT::Reader.new do |l, data, size|
        state = LuaState.new(l)
        Box(typeof(cb)).unbox(data).call(state, size)
      end
      case LibLuaJIT.lua_load(self, proc, box, chunk_name)
      when LibLuaJIT::LUA_ERRSYNTAX
        raise "Lua syntax error"
      when LibLuaJIT::LUA_ERRMEM
        raise "Lua memory allocation error"
      end
    end

    def execute(code : String) : Nil
      if (r = LibLuaJIT.luaL_loadstring(self, code)) != 0
        raise "Error(#{r}): Failed to load code into Lua"
      end
      case LibLuaJIT.lua_pcall(self, 0, LibLuaJIT::LUA_MULTRET, 0)
      when LibLuaJIT::LUA_ERRRUN
        raise "Lua runtime error"
      when LibLuaJIT::LUA_ERRMEM
        raise "Lua memory allocation error"
      when LibLuaJIT::LUA_ERRERR
        raise "Error while running error handler function"
      end
    end

    def execute(path : Path) : Nil
      if (r = LibLuaJIT.luaL_loadfile(self, path.to_s)) != 0
        raise "Error(#{r}): Failed to load file into Lua"
      end
      case LibLuaJIT.lua_pcall(self, 0, LibLuaJIT::LUA_MULTRET, 0)
      when LibLuaJIT::LUA_ERRRUN
        raise "Lua runtime error"
      when LibLuaJIT::LUA_ERRMEM
        raise "Lua memory allocation error"
      when LibLuaJIT::LUA_ERRERR
        raise "Error while running error handler function"
      end
    end
  end
end
