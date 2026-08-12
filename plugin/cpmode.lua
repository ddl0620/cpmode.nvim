-- Entry point for the plugin
-- This file is automatically sourced by Neovim

if vim.g.loaded_cpmode then
  return
end
vim.g.loaded_cpmode = 1

local function cmd(name, fn, desc)
  vim.api.nvim_create_user_command(name, fn, { desc = desc })
end

cmd('Cpm', function()
  require('cpmode').toggle()
end, 'Toggle competitive programming layout')

cmd('Cpru', function()
  require('cpmode').run()
end, 'Compile and run the current file with the input pane as stdin')

cmd('Cpre', function()
  require('cpmode').reset_io()
end, 'Clear the input and output panes')

cmd('Cpt', function()
  require('cpmode.template').insert_template()
end, 'Insert the language template at the cursor')

cmd('Cpdb', function()
  require('cpmode').debug()
end, 'Build a debug binary and start a gdb DAP session')

cmd('Cpi', function()
  require('cpmode').focus_input()
end, 'Jump to the input pane')
