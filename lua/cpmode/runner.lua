local M = {}
local buffers = require('cpmode.buffers')
local config = require('cpmode.config')

local function get_file_info(bufnr)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local filename = vim.fn.fnamemodify(filepath, ':t')
  local filedir = vim.fn.fnamemodify(filepath, ':p:h')
  local filebase = vim.fn.fnamemodify(filepath, ':t:r')
  local fileext = vim.fn.fnamemodify(filepath, ':e')
  
  return {
    path = filepath,
    name = filename,
    dir = filedir,
    base = filebase,
    ext = fileext,
  }
end

local function detect_language(ext)
  local lang_map = {
    cpp = 'cpp',
    cc = 'cpp',
    cxx = 'cpp',
    c = 'c',
    java = 'java',
    py = 'python',
  }
  
  return lang_map[ext]
end

local function compile(file_info, lang)
  local compile_cmd = config.options.compile_commands[lang]
  
  if not compile_cmd then
    return true, nil -- No compilation needed
  end
  
  local output_file = file_info.base
  if vim.fn.has('win32') == 1 then
    output_file = output_file .. '.exe'
  end
  
  local cmd = string.format(compile_cmd, file_info.name, output_file)
  
  -- Change to file directory
  local current_dir = vim.fn.getcwd()
  vim.cmd('cd ' .. vim.fn.fnameescape(file_info.dir))
  
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  -- Restore directory
  vim.cmd('cd ' .. vim.fn.fnameescape(current_dir))
  
  if exit_code ~= 0 then
    return false, result
  end
  
  return true, output_file
end

local function run_program(file_info, lang, executable, input_content)
  local run_cmd = config.options.run_commands[lang]
  
  if not run_cmd then
    return false, "No run command configured for " .. lang
  end
  
  local program = executable or file_info.name
  local cmd = string.format(run_cmd, program)
  
  -- Change to file directory
  local current_dir = vim.fn.getcwd()
  vim.cmd('cd ' .. vim.fn.fnameescape(file_info.dir))
  
  -- Create temporary input file
  local temp_input = vim.fn.tempname()
  local f = io.open(temp_input, 'w')
  if f then
    f:write(input_content)
    f:close()
  end
  
  -- Run with input redirection and timeout
  local full_cmd = string.format('timeout %d %s < %s 2>&1', 
    config.options.timeout, cmd, vim.fn.shellescape(temp_input))
  
  -- For Windows, use different timeout command
  if vim.fn.has('win32') == 1 then
    full_cmd = string.format('%s < %s 2>&1', cmd, vim.fn.shellescape(temp_input))
  end
  
  local output = vim.fn.system(full_cmd)
  local exit_code = vim.v.shell_error
  
  -- Clean up
  vim.fn.delete(temp_input)
  vim.cmd('cd ' .. vim.fn.fnameescape(current_dir))
  
  -- Check for timeout (exit code 124 on Unix)
  if exit_code == 124 then
    output = output .. "\n\n[Time Limit Exceeded]"
  elseif exit_code ~= 0 then
    output = output .. "\n\n[Runtime Error - Exit Code: " .. exit_code .. "]"
  end
  
  return true, output
end

function M.run(state)
  -- Strategy: Run the file from the current window if it's a code file,
  -- otherwise fall back to the main window
  
  local current_win = vim.api.nvim_get_current_win()
  local target_buf = nil
  
  -- Check if current window is one of the I/O windows
  if current_win == state.input_win or current_win == state.output_win then
    -- We're in an I/O window, use the main window's buffer
    if state.main_win and vim.api.nvim_win_is_valid(state.main_win) then
      target_buf = vim.api.nvim_win_get_buf(state.main_win)
    end
  else
    -- We're in a code window (could be main or a split), use current buffer
    target_buf = vim.api.nvim_get_current_buf()
  end
  
  if not target_buf or not vim.api.nvim_buf_is_valid(target_buf) then
    vim.notify("No valid buffer to run", vim.log.levels.ERROR)
    return
  end
  
  -- Check if it's an I/O buffer
  if target_buf == state.input_buf or target_buf == state.output_buf then
    vim.notify("Cannot run I/O buffer. Focus on a code file.", vim.log.levels.ERROR)
    return
  end
  
  -- Check if the buffer is an actual file
  local buftype = vim.api.nvim_buf_get_option(target_buf, 'buftype')
  if buftype ~= '' then
    vim.notify("Current buffer is not a file", vim.log.levels.ERROR)
    return
  end
  
  -- Save the buffer first (if modified)
  if vim.api.nvim_buf_get_option(target_buf, 'modified') then
    vim.api.nvim_buf_call(target_buf, function()
      vim.cmd('write')
    end)
  end
  
  -- Get file info
  local file_info = get_file_info(target_buf)
  
  if file_info.path == '' then
    vim.notify("Please save the file first", vim.log.levels.ERROR)
    return
  end
  
  -- Detect language
  local lang = detect_language(file_info.ext)
  
  if not lang then
    vim.notify("Unsupported file type: " .. file_info.ext, vim.log.levels.ERROR)
    return
  end
  
  -- Get input
  local input_content = buffers.get_input_content(state.input_buf)
  
  -- Show compilation message with filename
  buffers.set_output_content(state.output_buf, "Compiling " .. file_info.name .. "...")
  vim.cmd('redraw')
  
  -- Compile if needed
  local success, result = compile(file_info, lang)
  
  if not success then
    buffers.set_output_content(state.output_buf, "[Compilation Error: " .. file_info.name .. "]\n\n" .. result)
    vim.notify("Compilation failed: " .. file_info.name, vim.log.levels.ERROR)
    return
  end
  
  -- Show running message with filename
  buffers.set_output_content(state.output_buf, "Running " .. file_info.name .. "...")
  vim.cmd('redraw')
  
  -- Run program
  success, result = run_program(file_info, lang, result, input_content)
  
  if not success then
    buffers.set_output_content(state.output_buf, "[Error: " .. file_info.name .. "]\n\n" .. result)
    vim.notify("Execution failed: " .. file_info.name, vim.log.levels.ERROR)
    return
  end
  
  -- Display output (clean, no headers)
  buffers.set_output_content(state.output_buf, result)
  vim.notify("✓ " .. file_info.name, vim.log.levels.INFO)
end

return M