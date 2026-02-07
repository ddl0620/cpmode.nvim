-- Entry point for the plugin
-- This file is automatically sourced by Neovim

if vim.g.loaded_cpmode then
  return
end
vim.g.loaded_cpmode = 1

-- Create user commands
vim.api.nvim_create_user_command('Cpm', function()
  require('cpmode').toggle()
end, {})

vim.api.nvim_create_user_command('Cpru', function()
  require('cpmode').run()
end, {})

vim.api.nvim_create_user_command('Cpre', function()
  require('cpmode').reset_io()
end, {})

vim.api.nvim_create_user_command('Cpt', function()
  require('cpmode.template').insert_template()
end, {})