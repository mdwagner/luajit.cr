require "./src/luajit"

pp! Luajit::TRACKABLES.size
Luajit.run do |state|
  state.new_table
  table_index = state.size

  state.tap do |_state|
    _state.push("gen_secret_key")
    _state.push do |_s|
      puts Random::Secure.base64(32)
      0
    end
    _state.set_table(table_index)
  end

  state.set_global("Lucky")

  begin
    Luajit.run do |_state|
      _state.new_table
      i = _state.size

      _state.tap do |s|
        s.push("gen_secret_key")
        s.push do |_|
          puts Random::Secure.base64(32)
          0
        end
        s.set_table(i)
      end

      _state.set_global("Crystal")

      begin
      _state.execute <<-LUA
      Crystal.gen_secret_key()
      print("Hello Inside\n")
      LUA
      rescue ee
        pp! ee
      end

      pp! Luajit::TRACKABLES
    end
  rescue e
    pp! e
  end

  state.execute <<-LUA
  Lucky.gen_secret_key()
  print("Hello Outside")
  LUA

  pp! Luajit::TRACKABLES
end
pp! Luajit::TRACKABLES.size
