module Luajit
  class LuaProtectedError < Exception
    protected def initialize(state : LuaState, status : LuaStatus, lua_method : String)
      super(
        String.build do |str|
          if state.is_string?(-1)
            str << state.to_string(-1) << ' '
            state.pop(1)
          end
          str << "(#{status.to_s}) from '#{lua_method}'"
        end
      )
    end
  end

  class LuaArgumentError < Exception
  end
end
