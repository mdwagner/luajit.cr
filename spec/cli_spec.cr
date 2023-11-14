require "./spec_helper"

describe "LuckyCLI" do
  it "should build a task in Lua and execute it" do
    Luajit.run do |l|
      l.new_table
      table_idx = l.size

      l.push("register_task")
      l.push do |state|
        state.assert_args_eq(1)
        state.assert_table?(-1)

        #if any = state.to_any?
          #pp! any["args"]["derp"].as_a
        #end
        0
      end
      l.set_table(table_idx)

      l.push_value(table_idx)
      l.set_global("Lucky")
      l.remove(table_idx)

      l.execute <<-'LUA'
      Lucky.register_task({
        name = "gen.secret_key",
        summary = "Generate a new secret key",
        help_message = "My help message",
        bob = {},
        args = {
          derp = {1, 2, 3, true, function() end, 6},
          test_mode = {
            type = "switch",
            description = "Run in test mode. Doesn't charge cards.",
            shortcut = "-t",
          },
          model = {
            type = "arg",
            description = "Only reindex this model",
            shortcut = "-m",
            optional = true,
            format = "^[A-Z]",
          },
          limit = {
            type = "int32",
            description = "limit (1000, 10_000, etc.)",
            shortcut = "-l",
            default = 1000,
          },
          max_amount = {
            type = "float64",
            description = "specifies largest invoice amount",
            shortcut = "-x",
            default = 25.0,
          },
          model_name = {
            type = "positional",
            description = "The name of the model",
            format = "^[A-Z]",
          },
          column_types = {
            type = "positional",
            description = "The columns for this model in format: col:type",
            to_end = true,
            format = "^\\w+:\\w+$",
          },
        },
        fn = function(args) end,
      })
      LUA

      l.status.ok?.should be_true
    end
  end
end
