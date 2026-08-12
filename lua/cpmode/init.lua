local M = {}

M.state = {
  active = false,
  main_buf = nil,
  input_buf = nil,
  output_buf = nil,
  main_win = nil,
  input_win = nil,
  output_win = nil,
}

local config = require('cpmode.config')
local layout = require('cpmode.layout')
local buffers = require('cpmode.buffers')

function M.setup(opts)
  config.setup(opts)
end

function M.is_active()
  return M.state.active
end

function M.toggle()
  if M.state.active then
    M.disable()
  else
    M.enable()
  end
end

function M.enable()
  if M.state.active then
    vim.notify('CP Mode already active', vim.log.levels.WARN)
    return
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[current_buf].filetype

  if vim.bo[current_buf].buftype ~= '' or filetype == 'alpha' or filetype == 'NvimTree' then
    vim.notify('Please open a file first', vim.log.levels.WARN)
    return
  end

  M.state.main_buf = current_buf
  M.state.input_buf = buffers.create_input_buffer()
  M.state.output_buf = buffers.create_output_buffer()

  layout.create_layout(M.state)

  M.state.active = true
  vim.notify('CP Mode enabled', vim.log.levels.INFO)
end

function M.disable()
  if not M.state.active then
    return
  end

  -- Stop the autocmds before tearing windows down, otherwise they fire
  -- against windows that are in the middle of being closed.
  layout.teardown()
  M.state.active = false

  for _, win in ipairs({ M.state.input_win, M.state.output_win }) do
    if win and vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  for _, buf in ipairs({ M.state.input_buf, M.state.output_buf }) do
    if buf and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end

  if M.state.main_win and vim.api.nvim_win_is_valid(M.state.main_win) then
    vim.api.nvim_set_current_win(M.state.main_win)
  end

  M.state.main_buf = nil
  M.state.input_buf = nil
  M.state.output_buf = nil
  M.state.main_win = nil
  M.state.input_win = nil
  M.state.output_win = nil

  vim.notify('CP Mode disabled', vim.log.levels.INFO)
end

-- Move the cursor to the input pane so a test case can be typed straight away.
function M.focus_input()
  if not M.state.active then
    vim.notify('CP Mode not active', vim.log.levels.WARN)
    return
  end
  if M.state.input_win and vim.api.nvim_win_is_valid(M.state.input_win) then
    vim.api.nvim_set_current_win(M.state.input_win)
  end
end

function M.focus_code()
  if M.state.main_win and vim.api.nvim_win_is_valid(M.state.main_win) then
    vim.api.nvim_set_current_win(M.state.main_win)
  end
end

function M.run()
  if not M.state.active then
    vim.notify('CP Mode not active. Use :Cpm first', vim.log.levels.WARN)
    return
  end

  require('cpmode.runner').run(M.state)
end

function M.debug()
  require('cpmode.debug').start()
end

function M.reset_io()
  if not M.state.active then
    vim.notify('CP Mode not active', vim.log.levels.WARN)
    return
  end

  buffers.clear_buffer(M.state.input_buf)
  buffers.clear_buffer(M.state.output_buf, { readonly = true })
  vim.notify('I/O buffers reset', vim.log.levels.INFO)
end

return M
