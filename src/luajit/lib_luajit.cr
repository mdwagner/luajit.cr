module Luajit
  {% if flag?(:win32) %}
    # NOTE: Looks up either "lua51.lib", "lua51-static.lib", or "lua51-dynamic.lib"
    @[Link("lua51")]
  {% else %}
    @[Link("luajit")]
  {% end %}
  {% if compare_versions(Crystal::VERSION, "1.11.0") >= 0 %}
    # EXPERIMENTAL: Requires "-Dpreview_dll" for dynamic linking
    @[Link(dll: "lua51.dll")]
  {% end %}
  lib LibLuaJIT
    LUA_MULTRET        =      -1
    LUA_REGISTRYINDEX  = -10_000
    LUA_ENVIRONINDEX   = -10_001
    LUA_GLOBALSINDEX   = -10_002
    LUA_OK             =       0
    LUA_YIELD          =       1
    LUA_ERRRUN         =       2
    LUA_ERRSYNTAX      =       3
    LUA_ERRMEM         =       4
    LUA_ERRERR         =       5
    LUA_ERRFILE        =       6
    LUA_TNONE          =      -1
    LUA_TNIL           =       0
    LUA_TBOOLEAN       =       1
    LUA_TLIGHTUSERDATA =       2
    LUA_TNUMBER        =       3
    LUA_TSTRING        =       4
    LUA_TTABLE         =       5
    LUA_TFUNCTION      =       6
    LUA_TUSERDATA      =       7
    LUA_TTHREAD        =       8
    LUA_GCSTOP         =       0
    LUA_GCRESTART      =       1
    LUA_GCCOLLECT      =       2
    LUA_GCCOUNT        =       3
    LUA_GCCOUNTB       =       4
    LUA_GCSTEP         =       5
    LUA_GCSETPAUSE     =       6
    LUA_GCSETSTEPMUL   =       7
    LUA_HOOKCALL       =       0
    LUA_HOOKRET        =       1
    LUA_HOOKLINE       =       2
    LUA_HOOKCOUNT      =       3
    LUA_HOOKTAILRET    =       4
    LUA_MASKCALL       = 1 << LUA_HOOKCALL
    LUA_MASKRET        = 1 << LUA_HOOKRET
    LUA_MASKLINE       = 1 << LUA_HOOKLINE
    LUA_MASKCOUNT      = 1 << LUA_HOOKCOUNT
    LUA_IDSIZE         =     60
    LUAJIT_MODE_MASK   = 0x00ff
    LUAJIT_MODE_OFF    = 0x0000
    LUAJIT_MODE_ON     = 0x0100
    LUAJIT_MODE_FLUSH  = 0x0200
    LUA_NOREF          =     -2
    LUA_REFNIL         =     -1

    alias Int = LibC::Int
    alias SizeT = LibC::SizeT
    alias Char = LibC::Char
    alias Double = LibC::Double
    alias Long = LibC::Long
    alias VaList = LibC::VaList

    struct Debug
      event : Int
      name, namewhat, what, source : Char*
      currentline, nups, linedefined, lastlinedefined : Int
      short_src : Char[LUA_IDSIZE]
      i_ci : Int # private
    end

    alias State = Void
    alias CFunction = State* -> Int
    alias Reader = State*, Void*, SizeT* -> Char*
    alias Writer = State*, Void*, SizeT, Void* -> Int
    alias Alloc = Void*, Void*, SizeT, SizeT -> Void*
    alias Number = Double
    alias Integer = Long
    alias Hook = State*, Debug* -> Void
    alias Buffer = Void
    alias ProfileCallback = Void*, State*, Int, Int -> Void

    struct Reg
      name : Char*
      func : Void* # CFunction
    end

    enum LuajitMode
      Engine
      Debug
      Func
      AllFunc
      AllSubFunc
      Trace
      WrapFunc   = 0x10
      Max
    end

    fun lua_atpanic(l : State*, panicf : CFunction) : CFunction
    fun lua_call(l : State*, nargs : Int, nresults : Int) : Void
    fun lua_checkstack(l : State*, extra : Int) : Int
    fun lua_close(l : State*) : Void
    fun lua_concat(l : State*, n : Int) : Void
    fun lua_cpcall(l : State*, func : CFunction, ud : Void*) : Int
    fun lua_createtable(l : State*, narr : Int, nrec : Int) : Void
    fun lua_dump(l : State*, writer : Writer, data : Void*) : Int
    fun lua_equal(l : State*, index1 : Int, index2 : Int) : Int
    fun lua_error(l : State*) : Int
    fun lua_gc(l : State*, what : Int, data : Int) : Int
    fun lua_getallocf(l : State*, ud : Void**) : Alloc
    fun lua_getfenv(l : State*, index : Int) : Void
    fun lua_getfield(l : State*, index : Int, k : Char*) : Void
    fun lua_getmetatable(l : State*, index : Int) : Int
    fun lua_gettable(l : State*, index : Int) : Void
    fun lua_gettop(l : State*) : Int
    fun lua_insert(l : State*, index : Int) : Void
    fun lua_iscfunction(l : State*, index : Int) : Int
    fun lua_isnumber(l : State*, index : Int) : Int
    fun lua_isstring(l : State*, index : Int) : Int
    fun lua_isuserdata(l : State*, index : Int) : Int
    fun lua_lessthan(l : State*, index1 : Int, index2 : Int) : Int
    fun lua_load(l : State*, reader : Reader, data : Void*, chunkname : Char*) : Int
    fun lua_newstate(f : Alloc, ud : Void*) : State*
    fun lua_newthread(l : State*) : State*
    fun lua_newuserdata(l : State*, size : SizeT) : Void*
    fun lua_next(l : State*, index : Int) : Int
    fun lua_objlen(l : State*, index : Int) : SizeT
    fun lua_pcall(l : State*, nargs : Int, nresults : Int, errfunc : Int) : Int
    fun lua_pushboolean(l : State*, b : Int) : Void
    fun lua_pushcclosure(l : State*, fn : CFunction, n : Int) : Void
    fun lua_pushfstring(l : State*, fmt : Char*, ...) : Char*
    fun lua_pushinteger(l : State*, n : Integer) : Void
    fun lua_pushlightuserdata(l : State*, p : Void*) : Void
    fun lua_pushlstring(l : State*, s : Char*, len : SizeT) : Void
    fun lua_pushnil(l : State*) : Void
    fun lua_pushnumber(l : State*, n : Number) : Void
    fun lua_pushstring(l : State*, s : Char*) : Void
    fun lua_pushthread(l : State*) : Int
    fun lua_pushvalue(l : State*, index : Int) : Void
    fun lua_pushvfstring(l : State*, fmt : Char*, argp : VaList) : Char*
    fun lua_rawequal(l : State*, index1 : Int, index2 : Int) : Int
    fun lua_rawget(l : State*, index : Int) : Void
    fun lua_rawgeti(l : State*, index : Int, n : Int) : Void
    fun lua_rawset(l : State*, index : Int) : Void
    fun lua_rawseti(l : State*, index : Int, n : Int) : Void
    fun lua_remove(l : State*, index : Int) : Void
    fun lua_replace(l : State*, index : Int) : Void
    fun lua_resume(l : State*, narg : Int) : Int
    fun lua_setallocf(l : State*, f : Alloc, ud : Void*) : Void
    fun lua_setfenv(l : State*, index : Int) : Int
    fun lua_setfield(l : State*, index : Int, k : Char*) : Void
    fun lua_setmetatable(l : State*, index : Int) : Int
    fun lua_settable(l : State*, index : Int) : Void
    fun lua_settop(l : State*, index : Int) : Void
    fun lua_status(l : State*) : Int
    fun lua_toboolean(l : State*, index : Int) : Int
    fun lua_tocfunction(l : State*, index : Int) : CFunction
    fun lua_tointeger(l : State*, index : Int) : Integer
    fun lua_tolstring(l : State*, index : Int, len : SizeT*) : Char*
    fun lua_tonumber(l : State*, index : Int) : Number
    fun lua_topointer(l : State*, index : Int) : Void*
    fun lua_tostring(l : State*, index : Int) : Char*
    fun lua_tothread(l : State*, index : Int) : State*
    fun lua_touserdata(l : State*, index : Int) : Void*
    fun lua_type(l : State*, index : Int) : Int
    fun lua_typename(l : State*, tp : Int) : Char*
    fun lua_xmove(from : State*, to : State*, n : Int) : Void
    fun lua_yield(l : State*, nresults : Int) : Int

    fun lua_gethook(l : State*) : Hook
    fun lua_gethookcount(l : State*) : Int
    fun lua_gethookmask(l : State*) : Int
    fun lua_getinfo(l : State*, what : Char*, ar : Debug*) : Int
    fun lua_getlocal(l : State*, ar : Debug*, n : Int) : Char*
    fun lua_getstack(l : State*, level : Int, ar : Debug*) : Int
    fun lua_getupvalue(l : State*, funcindex : Int, n : Int) : Char*
    fun lua_sethook(l : State*, f : Hook, mask : Int, count : Int) : Int
    fun lua_setlocal(l : State*, ar : Debug*, n : Int) : Char*
    fun lua_setupvalue(l : State*, funcindex : Int, n : Int) : Char*

    fun luaL_addchar(b : Buffer*, c : Char) : Void
    fun luaL_addlstring(b : Buffer*, s : Char*, l : SizeT) : Void
    fun luaL_addsize(b : Buffer*, n : SizeT) : Void
    fun luaL_addstring(b : Buffer*, s : Char*) : Void
    fun luaL_addvalue(b : Buffer*) : Void
    fun luaL_argerror(l : State*, narg : Int, extramsg : Char*) : Int
    fun luaL_buffinit(l : State*, b : Buffer*) : Void
    fun luaL_callmeta(l : State*, obj : Int, e : Char*) : Int
    fun luaL_checkany(l : State*, narg : Int) : Void
    fun luaL_checkinteger(l : State*, narg : Int) : Integer
    fun luaL_checklstring(l : State*, narg : Int, len : SizeT*) : Char*
    fun luaL_checknumber(l : State*, narg : Int) : Number
    fun luaL_checkoption(l : State*, narg : Int, _def : Char*, lst : Char**) : Int
    fun luaL_checkstack(l : State*, sz : Int, msg : Char*) : Void
    fun luaL_checktype(l : State*, narg : Int, t : Int) : Void
    fun luaL_checkudata(l : State*, narg : Int, tname : Char*) : Void*
    fun luaL_error(l : State*, fmt : Char*, ...) : Int
    fun luaL_getmetafield(l : State*, obj : Int, e : Char*) : Int
    fun luaL_gsub(l : State*, s : Char*, p : Char*, r : Char*) : Char*
    fun luaL_loadbuffer(l : State*, buff : Char*, sz : SizeT, name : Char*) : Int
    fun luaL_loadfile(l : State*, filename : Char*) : Int
    fun luaL_loadstring(l : State*, s : Char*) : Int
    fun luaL_newmetatable(l : State*, tname : Char*) : Int
    fun luaL_newstate : State*
    fun luaL_openlibs(l : State*) : Void
    fun luaL_optinteger(l : State*, narg : Int, d : Integer) : Integer
    fun luaL_optlstring(l : State*, narg : Int, d : Char*, len : SizeT*) : Char*
    fun luaL_optnumber(l : State*, narg : Int, d : Number) : Number
    fun luaL_prepbuffer(b : Buffer*) : Char*
    fun luaL_pushresult(b : Buffer*) : Void
    fun luaL_ref(l : State*, t : Int) : Int
    fun luaL_register(l : State*, libname : Char*, lr : Reg*) : Void
    fun luaL_typerror(l : State*, narg : Int, tname : Char*) : Int
    fun luaL_unref(l : State*, t : Int, ref : Int) : Void
    fun luaL_where(l : State*, lvl : Int) : Void

    fun luaopen_base(l : State*) : Int
    fun luaopen_table(l : State*) : Int
    fun luaopen_io(l : State*) : Int
    fun luaopen_os(l : State*) : Int
    fun luaopen_string(l : State*) : Int
    fun luaopen_math(l : State*) : Int
    fun luaopen_debug(l : State*) : Int
    fun luaopen_package(l : State*) : Int

    fun luaJIT_profile_dumpstack(l : State*, fmt : Char*, depth : Int, len : SizeT*) : Char*
    fun luaJIT_profile_start(l : State*, mode : Char*, cb : ProfileCallback, data : Void*) : Void
    fun luaJIT_profile_stop(l : State*) : Void
    fun luaJIT_setmode(l : State*, idx : Int, mode : Int) : Int

    fun lua_upvalueid(l : State*, idx : Int, n : Int) : Void*
    fun lua_upvaluejoin(l : State*, idx1 : Int, n1 : Int, idx2 : Int, n2 : Int) : Void
    fun lua_loadx(l : State*, reader : Reader, dt : Void*, chunkname : Char*, mode : Char*) : Int
    fun lua_version(l : State*) : Number*
    fun lua_copy(l : State*, fromidx : Int, toidx : Int) : Void
    fun lua_tonumberx(l : State*, idx : Int, isnum : Int*) : Number
    fun lua_tointegerx(l : State*, idx : Int, isnum : Int*) : Integer
    fun lua_isyieldable(l : State*) : Int

    fun luaL_fileresult(l : State*, stat : Int, fname : Char*) : Int
    fun luaL_execresult(l : State*, stat : Int) : Int
    fun luaL_loadfilex(l : State*, filename : Char*, mode : Char*) : Int
    fun luaL_loadbufferx(l : State*, buff : Char*, sz : SizeT, name : Char*, mode : Char*) : Int
    fun luaL_traceback(l : State*, l1 : State*, msg : Char*, level : Int) : Void
    fun luaL_setfuncs(l : State*, lr : Reg*, nup : Int) : Void
    fun luaL_pushmodule(l : State*, modname : Char*, sizehint : Int) : Void
    fun luaL_testudata(l : State*, ud : Int, tname : Char*) : Void*
    fun luaL_setmetatable(l : State*, tname : Char*) : Void
    fun luaL_findtable(l : State*, idx : Int, fname : Char*, szhint : Int) : Char*
    fun luaL_openlib(l : State*, libname : Char*, lr : Reg*, nup : Int) : Void

    fun luaopen_bit(l : State*) : Int
    fun luaopen_ffi(l : State*) : Int
    fun luaopen_jit(l : State*) : Int
  end

  alias LuaCFunction = LibLuaJIT::CFunction
  alias LuaDebug = LibLuaJIT::Debug
  alias LuaHook = LibLuaJIT::Hook
end
