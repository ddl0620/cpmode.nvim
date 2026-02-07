local M = {}

M.state = {
  active = false,
  main_buf = nil,
  input_buf = nil,
  output_buf = nil,
  main_win = nil,
  input_win = nil,
  output_win = nil,
  original_layout = nil,
}

local config = require('cpmode.config')
local layout = require('cpmode.layout')
local runner = require('cpmode.runner')
local buffers = require('cpmode.buffers')

-- Setup function for lazy.nvim
function M.setup(opts)
  config.setup(opts)
end

-- Toggle CP mode
function M.toggle()
  if M.state.active then
    M.disable()
  else
    M.enable()
  end
end

-- Enable CP mode
function M.enable()
  if M.state.active then
    vim.notify("CP Mode already active", vim.log.levels.WARN)
    return
  end

  -- Store current buffer as main buffer
  local current_buf = vim.api.nvim_get_current_buf()
  
  -- Don't activate if we're in alpha or nvim-tree
  local buftype = vim.api.nvim_buf_get_option(current_buf, 'buftype')
  local filetype = vim.api.nvim_buf_get_option(current_buf, 'filetype')
  
  if buftype ~= '' or filetype == 'alpha' or filetype == 'NvimTree' then
    vim.notify("Please open a file first", vim.log.levels.WARN)
    return
  end

  M.state.main_buf = current_buf

  -- Create I/O buffers
  M.state.input_buf = buffers.create_input_buffer()
  M.state.output_buf = buffers.create_output_buffer()

  -- Create layout
  layout.create_layout(M.state)

  M.state.active = true
  
  vim.notify("CP Mode enabled", vim.log.levels.INFO)
end

-- Disable CP mode
function M.disable()
  if not M.state.active then
    return
  end

  -- Close I/O windows
  if M.state.input_win and vim.api.nvim_win_is_valid(M.state.input_win) then
    vim.api.nvim_win_close(M.state.input_win, true)
  end
  if M.state.output_win and vim.api.nvim_win_is_valid(M.state.output_win) then
    vim.api.nvim_win_close(M.state.output_win, true)
  end

  -- Delete I/O buffers
  if M.state.input_buf and vim.api.nvim_buf_is_valid(M.state.input_buf) then
    vim.api.nvim_buf_delete(M.state.input_buf, { force = true })
  end
  if M.state.output_buf and vim.api.nvim_buf_is_valid(M.state.output_buf) then
    vim.api.nvim_buf_delete(M.state.output_buf, { force = true })
  end

  -- Focus main window
  if M.state.main_win and vim.api.nvim_win_is_valid(M.state.main_win) then
    vim.api.nvim_set_current_win(M.state.main_win)
  end

  M.state.active = false
  M.state.main_buf = nil
  M.state.input_buf = nil
  M.state.output_buf = nil
  M.state.main_win = nil
  M.state.input_win = nil
  M.state.output_win = nil

  vim.notify("CP Mode disabled", vim.log.levels.INFO)
end

-- Run the current file
function M.run()
  if not M.state.active then
    vim.notify("CP Mode not active. Use :CPMode first", vim.log.levels.WARN)
    return
  end

  runner.run(M.state)
end

-- Reset I/O buffers
function M.reset_io()
  if not M.state.active then
    vim.notify("CP Mode not active", vim.log.levels.WARN)
    return
  end

  buffers.clear_buffer(M.state.input_buf)
  buffers.clear_buffer(M.state.output_buf, { readonly = true })
  vim.notify("I/O buffers reset", vim.log.levels.INFO)
end

return M