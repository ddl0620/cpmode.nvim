local M = {}

local AUGROUP = 'CPModeFileOpen'

local function find_nvim_tree_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'NvimTree' then
      return win
    end
  end
  return nil
end

function M.create_layout(state)
  local config = require('cpmode.config')

  local current_win = vim.api.nvim_get_current_win()
  local tree_win = find_nvim_tree_win()

  -- Collapse everything except the file we are working on and the tree.
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= current_win and win ~= tree_win then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  vim.api.nvim_set_current_win(current_win)
  state.main_win = current_win

  -- Input pane on the right.
  vim.cmd('rightbelow vsplit')
  local input_win = vim.api.nvim_get_current_win()

  local total_width = vim.o.columns
  if tree_win and vim.api.nvim_win_is_valid(tree_win) then
    total_width = total_width - vim.api.nvim_win_get_width(tree_win)
  end
  vim.api.nvim_win_set_width(input_win, math.floor(total_width * config.options.io_pane_width / 100))

  vim.api.nvim_win_set_buf(input_win, state.input_buf)
  state.input_win = input_win

  -- Output pane underneath it.
  vim.cmd('rightbelow split')
  local output_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(output_win, state.output_buf)
  state.output_win = output_win

  local io_height = vim.api.nvim_win_get_height(input_win) + vim.api.nvim_win_get_height(output_win)
  vim.api.nvim_win_set_height(input_win, math.floor(io_height * config.options.input_height / 100))

  vim.api.nvim_set_current_win(state.main_win)

  M.setup_file_open_autocmd(state)
end

-- Files opened from anywhere (tree, tab bar, picker) must land in the code
-- pane, never on top of the I/O panes.
function M.setup_file_open_autocmd(state)
  local group = vim.api.nvim_create_augroup(AUGROUP, { clear = true })

  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function()
      if not state.active then
        return
      end

      local current_win = vim.api.nvim_get_current_win()
      local current_buf = vim.api.nvim_get_current_buf()
      local is_io_buf = current_buf == state.input_buf or current_buf == state.output_buf

      if current_win == state.input_win or current_win == state.output_win then
        if not is_io_buf then
          -- Put the I/O buffer back and redirect the file to the code pane.
          local restore = current_win == state.input_win and state.input_buf or state.output_buf
          vim.api.nvim_win_set_buf(current_win, restore)

          if state.main_win and vim.api.nvim_win_is_valid(state.main_win) then
            vim.api.nvim_win_set_buf(state.main_win, current_buf)
            vim.api.nvim_set_current_win(state.main_win)
            state.main_buf = current_buf
          end
        end
      elseif current_win == state.main_win and not is_io_buf then
        -- Keep track of what the code pane is showing.
        state.main_buf = current_buf
      end
    end,
  })
end

function M.teardown()
  pcall(vim.api.nvim_del_augroup_by_name, AUGROUP)
end

return M
