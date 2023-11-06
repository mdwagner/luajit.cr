require "./src/luajit"

Luajit.run do |l|
  # Lucky (global table)
  # register_task (function) (string, function)
  # function(task)
  #   - task: table
  #     - summary: function (string)
  #     - switch: function (table)
  #     - arg: function (table
  #     - positional: function (table)

  l.execute <<-'LUA'
  --print("Hello World\n")
  local fn = function()
    return 5
  end
  return fn

  LUCKY_TASKS = {} -- LUA_GLOBALSINDEX

  state.push_value(-1) -- function value
  luaL_ref(L, LUA_REGISTRYINDEX) -- function value index

  l = Lucky.tasks.new
  l:register_task()
  Lucky.register_tasks(l)

  Lucky.register_task("gen.secret_key", function(task)
    task.summary("Generate a new secret key")

    task.switch({
      name = "test_mode",
      desc = "Run in test mode. Doesn't charge cards.",
      shortcut = "-t",
    })
    task.arg({
      name = "model",
      desc = "Only reindex this model",
      shortcut = "-m",
      optional = true,
      format = "^[A-Z]"
    })

    task.call(function()
      -- function definition
      -- luaL_ref() to store function reference and not be GC'd
      -- luaL_unref() to release function reference
    end)
  end)
  LUA

  # l.get_global("LUCKY_TASKS")
  # loop through keys





  #l.get_global("LUCKY_TASKS")
  #l.get_type(1) # table

  #pp! l.get_type(1)
  #l.push_value(1)
  #l.pcall(0, 1)
  #pp! l.get_type(2)
  #pp! l.to_i(2)
end


#pp! Luajit::TRACKABLES.size
#Luajit.run do |state|
  #state.new_table
  #table_index = state.size

  #state.tap do |_state|
    #_state.push("gen_secret_key")
    #_state.push do |_s|
      #puts Random::Secure.base64(32)
      #0
    #end
    #_state.set_table(table_index)
  #end

  #state.set_global("Lucky")

  #begin
    #Luajit.run do |_state|
      #_state.new_table
      #i = _state.size

      #_state.tap do |s|
        #s.push("gen_secret_key")
        #s.push do |_|
          #puts Random::Secure.base64(32)
          #0
        #end
        #s.set_table(i)
      #end

      #_state.set_global("Crystal")

      #begin
      #_state.execute <<-LUA
      #Crystal.gen_secret_key()
      #print("Hello Inside\n")
      #LUA
      #rescue ee
        #pp! ee
      #end

      #pp! Luajit::TRACKABLES
    #end
  #rescue e
    #pp! e
  #end

  #state.execute <<-LUA
  #Lucky.gen_secret_key()
  #print("Hello Outside")
  #LUA

  #pp! Luajit::TRACKABLES
#end
#pp! Luajit::TRACKABLES.size
