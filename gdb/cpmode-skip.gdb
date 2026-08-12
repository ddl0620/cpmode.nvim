# cpmode.nvim - gdb settings for competitive programming.
#
# Loaded via `gdb -i dap -x <this file>`. The goal is that "step into"
# only ever lands in code you wrote, never inside libstdc++.

# Never block the DAP handshake with an interactive debuginfod prompt.
set debuginfod enabled off

# Don't stop to ask "continue? (y or n)" - there is no terminal to answer on.
set confirm off
set pagination off

# Required for `args = "< input.txt"` redirection to be handled by the shell.
set startup-with-shell on

# Show containers as values rather than as internal pointer soup.
set print pretty on
set print object on

# Competitive programming arrays get long; 200 elements is plenty to eyeball
# without flooding the variables panel.
set print elements 200
set print repeats 10

# --- Keep `step` inside user code -------------------------------------------
# STL headers are templates instantiated into your binary, so they carry debug
# info and `step` would otherwise descend into them.
skip -gfi /usr/include/c++/*/*
skip -gfi /usr/include/c++/*/*/*
skip -gfi /usr/include/c++/*/*/*/*
skip -gfi /usr/include/*/c++/*/*
skip -gfi /usr/include/bits/*
skip -gfi /usr/lib/gcc/*/*

skip -rfu ^std::
skip -rfu ^__gnu_cxx::
skip -rfu ^__gnu_debug::
