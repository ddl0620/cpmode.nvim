local M = {}

M.options = {
  -- Width of the I/O pane (percentage or absolute)
  io_pane_width = 40, -- 40% of screen width
  
  -- Height split for input/output (percentage)
  input_height = 50, -- 50% of I/O pane height
  
  -- Compilation commands for different languages
  compile_commands = {
    cpp = "g++ -std=c++17 -O2 -Wall %s -o %s",
    c = "gcc -std=c11 -O2 -Wall %s -o %s",
    java = "javac %s",
    python = nil, -- No compilation needed
  },
  
  -- Run commands for different languages
  run_commands = {
    cpp = "./%s",
    c = "./%s",
    java = "java %s",
    python = "python3 %s",
    python2 = "python %s",
  },
  
  -- Timeout for program execution (in seconds)
  timeout = 5,
  
  -- Templates for different languages
  templates = {
    cpp = [[
#include <bits/stdc++.h>

using namespace std;

typedef long long ll;
typedef long double ld;
typedef vector<int> vi;
typedef vector<ll> vll;
const ll MOD = 1e9 + 7;
const double eps = 1e-12;

#define pb push_back
#define ln "\n"
void solve() {
    
}
int main() {
    ios_base::sync_with_stdio(0);
    cin.tie(0);
    cout.tie(0);
    solve();
    return 0;
}]],
    
    c = [[
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

void solve() {
    
}

int main() {
    solve();
    return 0;
}]],
    
    java = [[import java.util.*;
import java.io.*;

public class Main {
    static BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
    static PrintWriter out = new PrintWriter(System.out);
    
    public static void solve() throws IOException {
        
    }
    
    public static void main(String[] args) throws IOException {
        solve();
        out.close();
    }
}]],
    
    python = [[import sys
from collections import *
from math import *

def solve():
    pass

if __name__ == "__main__":
    solve()]],
  },
}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M