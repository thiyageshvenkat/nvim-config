local function ensure_dir(dir)
  if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
end

local function sanitize(s)
  s = s:gsub("[/\\:%*%?\"%<%>%|]", "-")
  s = s:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  return s
end

local function usaco_contest_code(contest)
  local year = contest:match("(%d%d%d%d)") or "0000"
  local y = tonumber(year) or 0
  local c = contest:lower()
  local month_letter, roman = "X", "i"
  if c:find("dec") then month_letter, roman = "D", "i"
  elseif c:find("jan") then month_letter, roman = "J", "ii"
  elseif c:find("feb") then month_letter, roman = "F", "iii"
  elseif c:find("open") then month_letter, roman = "O", "iv"
  end
  if y >= 2026 then return year .. roman end
  return year .. month_letter
end

local function div_letter(task)
  local s = ((task.name or "") .. " " .. (task.group or "") .. " " .. (task.url or "")):lower()
  if s:find("bronze") then return "B" end
  if s:find("silver") then return "S" end
  if s:find("gold") then return "G" end
  if s:find("platinum") then return "P" end
  return "X"
end

local function prob_num(task)
  local n = (task.name or ""):match("[Pp]roblem%s*(%d+)")
  if n then return n end
  n = (task.name or ""):match("^%s*(%d+)[%.)%s]")
  if n then return n end
  n = (task.name or ""):match("(%d+)")
  return n or "0"
end

local function split_group(group)
  local hyphen = group and group:find(" %- ")
  if not hyphen then return group or "unknown", "unknown_contest" end
  local judge = group:sub(1, hyphen - 1)
  local contest = group:sub(hyphen + 3)
  return judge, contest
end

return {
  {
    "xeluxee/competitest.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = { "CompetiTest" },
    keys = {
      { "<leader>tr", "<cmd>CompetiTest run<CR>", desc = "Run" },
      { "<leader>tu", "<cmd>CompetiTest show_ui<CR>", desc = "UI" },
      { "<leader>tp", "<cmd>CompetiTest receive problem<CR>", desc = "Receive problem" },
      { "<leader>tc", "<cmd>CompetiTest receive contest<CR>", desc = "Receive contest" },
    },
    config = function()
      local template_dir = vim.fn.stdpath("config") .. "/templates"
      local tpl = template_dir .. "/competitest.cpp"
      ensure_dir(template_dir)

      if vim.fn.filereadable(tpl) == 0 then
        vim.fn.writefile({
          "/*",
          "  Problem: $(PROBLEM)",
          "  Contest: $(CONTEST)",
          "  Judge:   $(JUDGE)",
          "  URL:     $(URL)",
          "  Limits:  $(TIMELIM) ms, $(MEMLIM) KB",
          "  Start:   $(DATE)",
          "*/",
          "",
          "#include <iostream>",
          "#include <vector>",
          "#include <string>",
          "#include <algorithm>",
          "#include <unordered_map>",
          "#include <map>",
          "#include <set>",
          "#include <queue>",
          "#include <stack>",
          "#include <cmath>",
          "#include <climits>",
          "#include <iomanip>",
          "#include <numeric>",
          "",
          "#define FASTIO ios::sync_with_stdio(false); cin.tie(NULL); cout.tie(NULL);",
          "",
          "using namespace std;",
          "",
          "int main() {",
          "    FASTIO;",
          "",
          "    return 0;",
          "}",
        }, tpl)
      end

      local cp_root = "/mnt/c/Users/ven12/usaco"
      
      require("competitest").setup({
        runner_ui = { interface = "split" },
        compile_directory = "$(ABSDIR)",
        compile_command = {
          cpp = {
            exec = "g++",
            args = { "-std=c++17", "-O2", "-Wall", "$(FABSPATH)", "-o", "/tmp/$(FNOEXT)" },
          },
        },
        run_command = { cpp = { exec = "/tmp/$(FNOEXT)" } },
        received_files_extension = "cpp",
        template_file = { cpp = tpl },
        evaluate_template_modifiers = true,
        received_problems_path = function(task, ext)
          local judge, contest = split_group(task.group)
          local name = sanitize(task.name or "problem")
          local jlow = (judge or ""):lower()
        
          ensure_dir(cp_root)
        
          if jlow:find("usaco") then
            local code = usaco_contest_code(contest)
            local div = div_letter(task)
            local num = prob_num(task)
            return string.format("%s/%s-%s%s.%s", cp_root, code, div, num, ext)
          end
        
          local clean_judge = sanitize(judge or "Unknown")
          return string.format("%s/%s_%s.%s", cp_root, clean_judge, name, ext)
        end,
      })
    end,
  },
}
