local M = {}

local function find_nvim_tree_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.api.nvim_buf_get_option(buf, 'filetype')
    if ft == 'NvimTree' then
      return win
    end
  end
  return nil
end

function M.create_layout(state)
  -- Save current window
  local current_win = vim.api.nvim_get_current_win()
  
  -- Check if nvim-tree is open
  local tree_win = find_nvim_tree_win()
  
  -- Close all windows except nvim-tree and current
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    if win ~= current_win and win ~= tree_win then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  -- Focus the main window (current window with the file)
  vim.api.nvim_set_current_win(current_win)
  state.main_win = current_win

  -- Create vertical split for I/O pane (this creates a split to the RIGHT)
  vim.cmd('rightbelow vsplit')
  local io_parent_win = vim.api.nvim_get_current_win()

  -- Set the width of I/O pane
  local config = require('cpmode.config')
  local total_width = vim.o.columns
  if tree_win then
    total_width = total_width - vim.api.nvim_win_get_width(tree_win)
  end
  local io_width = math.floor(total_width * config.options.io_pane_width / 100)
  vim.api.nvim_win_set_width(io_parent_win, io_width)

  -- Set input buffer in top pane (current window is the I/O pane)
  vim.api.nvim_win_set_buf(io_parent_win, state.input_buf)
  state.input_win = io_parent_win

  -- Create horizontal split for output (below the input)
  vim.cmd('rightbelow split')
  local output_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(output_win, state.output_buf)
  state.output_win = output_win

  -- Adjust heights to be equal
  local io_height = vim.api.nvim_win_get_height(state.input_win) + vim.api.nvim_win_get_height(state.output_win)
  local input_height = math.floor(io_height * config.options.input_height / 100)
  vim.api.nvim_win_set_height(state.input_win, input_height)

  -- Focus back to main window (left pane)
  vim.api.nvim_set_current_win(state.main_win)

  -- Set up autocommand to ensure files open in main pane
  M.setup_file_open_autocmd(state)
end

function M.setup_file_open_autocmd(state)
  -- Create autocommand group
  local group = vim.api.nvim_create_augroup("CPModeFileOpen", { clear = true })

  -- When a buffer is entered, if it's a file and we're in I/O windows, move to main
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      local current_win = vim.api.nvim_get_current_win()
      local current_buf = vim.api.nvim_get_current_buf()

      -- Check if we're in an I/O window
      if current_win == state.input_win or current_win == state.output_win then
        -- If the buffer is not an I/O buffer, move it to main window
        if current_buf ~= state.input_buf and current_buf ~= state.output_buf then
          -- Restore I/O buffer in current window
          if current_win == state.input_win then
            vim.api.nvim_win_set_buf(current_win, state.input_buf)
          else
            vim.api.nvim_win_set_buf(current_win, state.output_buf)
          end

          -- Set the new buffer in main window
          if state.main_win and vim.api.nvim_win_is_valid(state.main_win) then
            vim.api.nvim_win_set_buf(state.main_win, current_buf)
            vim.api.nvim_set_current_win(state.main_win)
            state.main_buf = current_buf
          end
        end
      end
    end,
  })

  -- Track when a buffer is entered in the main window so the main buffer stays in sync
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      local current_win = vim.api.nvim_get_current_win()
      local current_buf = vim.api.nvim_get_current_buf()

      -- If the main window now has a different buffer, update state.main_buf
      if current_win == state.main_win then
        if current_buf ~= state.input_buf and current_buf ~= state.output_buf then
          state.main_buf = current_buf
        end
      end
    end,
  })
end

return M