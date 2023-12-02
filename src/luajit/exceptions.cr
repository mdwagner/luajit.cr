module Luajit
  class LuaProtectedError < Exception
    def initialize(state : LuaState, status : LuaStatus, lua_method : String)
      err_message = String.build do |str|
        if state.is_string?(-1)
          str << state.to_string(-1) << ' '
          state.pop(1)
        end
        str << "(#{status.to_s}) from '#{lua_method}'"
      end
      super(err_message)
    end
  end

  class LuaArgumentError < Exception
  end
end
