module Luajit
  enum LuaGC
    # Stops the garbage collector
    Stop
    # Restarts the garbage collector
    Restart
    # Performs a full garbage-collection cycle
    Collect
    # Returns the current amount of memory (in KBs) in use by Lua
    Count
    # Returns the remainder of dividing the current amount of bytes of memory in use by Lua by 1024
    CountBytes
    # Performs an incremental step of garbage collection
    #
    # The step "size" is controlled by data (larger values mean more steps) in a non-specified way. If you want to control the step size you must experimentally tune the value of data. The function returns 1 if the step finished a garbage-collection cycle.
    Step
    # Sets data as the new value for the pause of the collector
    #
    # The function returns the previous value of the pause.
    SetPause
    # Sets data as the new value for the step multiplier of the collector
    #
    # The function returns the previous value of the step multiplier.
    SetStepMultiplier
  end
end
