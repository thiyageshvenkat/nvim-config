-- ~/.config/nvim/lua/plugins/competitest.lua
local function ensure_dir(dir)
  if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
end

local function sanitize(s)
  s = s:gsub("[/\\:%*%?\"%<%>%|]", "-")
  s = s:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  return s
end

-- USACO helpers: make 2013J / 2025ii style contest codes
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

  -- switch to roman for newer years (edit threshold if you want)
  if y >= 2024 then return year .. roman end
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
    dependencies = { "MunifTanjim/nui.nvim" }, -- required :contentReference[oaicite:1]{index=1}
    cmd = { "CompetiTest" },
    keys = {
      { "<leader>tr", "<cmd>CompetiTest run<CR>", desc = "CompetiTest: Run" },
      { "<leader>tu", "<cmd>CompetiTest show_ui<CR>", desc = "CompetiTest: Show UI" },
      { "<leader>tp", "<cmd>CompetiTest receive problem<CR>", desc = "CompetiTest: Receive problem" },
      { "<leader>tc", "<cmd>CompetiTest receive contest<CR>", desc = "CompetiTest: Receive contest" },
      { "<leader>tP", "<cmd>CompetiTest receive persistently<CR>", desc = "CompetiTest: Receive persistently" },
      { "<leader>ts", "<cmd>CompetiTest receive stop<CR>", desc = "CompetiTest: Stop receiving" },
    },
    config = function()
      -- Template header (problem info at top) :contentReference[oaicite:2]{index=2}
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
          "#include <bits/stdc++.h>",
          "using namespace std;",
          "",
          "int main() {",
          "  ios::sync_with_stdio(false);",
          "  cin.tie(nullptr);",
          "  ",
          "  return 0;",
          "}",
          "",
        }, tpl)
      end

      local cp_root = vim.fn.expand("~/cp/usaco")

      require("competitest").setup({
        runner_ui = { interface = "split" },
        split_ui = {
          position = "right",
          relative_to_editor = true,
          total_width = 0.45,
          -- your preferred “IDE-ish” layout:
          vertical_layout = {
            { 2, "tc" },
            { 3, { { 1, "so" }, { 1, "si" } } },
            { 3, { { 1, "eo" }, { 1, "se" } } },
          },
        },

        view_output_diff = true,

        -- compile/run (fixed: compile from file dir, pass absolute path)
        compile_directory = "$(ABSDIR)",
        compile_command = {
        cpp = {
        exec = "g++",
        args = { "-std=c++17", "-O2", "-Wall", "-Wextra", "$(FABSPATH)", "-o", "/tmp/$(FNOEXT)" },
        },
        },
        run_command = { cpp = { exec = "/tmp/$(FNOEXT)" } }, -- compile/run (fixed: compile from file dir, pass absolute path)
          compile_directory = "$(ABSDIR)",
        compile_command = {
          cpp = {
            exec = "g++",
            args = { "-std=c++17", "-O2", "-Wall", "-Wextra", "$(FABSPATH)", "-o", "/tmp/$(FNOEXT)" },
          },
        },
        run_command = { cpp = { exec = "/tmp/$(FNOEXT)" } },
        running_directory = "$(ABSDIR)",

        -- Competitive Companion receive :contentReference[oaicite:3]{index=3}
        companion_port = 27121,
        received_files_extension = "cpp",

        -- Problem-info header template :contentReference[oaicite:4]{index=4}
        template_file = { cpp = tpl },
        evaluate_template_modifiers = true,
        date_format = "%Y-%m-%d %H:%M:%S",

        -- Custom USACO naming: 2013J-G2.cpp / 2025ii-B3.cpp
        received_problems_prompt_path = false,
        received_problems_path = function(task, ext) -- supported :contentReference[oaicite:5]{index=5}
          local judge, contest = split_group(task.group)
          local jlow = (judge or ""):lower()

          if not jlow:find("usaco") then
            local dir = string.format("%s/received/%s/%s", vim.fn.expand("~/cp"), sanitize(judge), sanitize(contest))
            ensure_dir(dir)
            return string.format("%s/%s.%s", dir, sanitize(task.name or "problem"), ext)
          end

          local code = usaco_contest_code(contest)
          local div = div_letter(task)
          local num = prob_num(task)

          local dir = string.format("%s/%s", cp_root, code)
          ensure_dir(dir)
          return string.format("%s/%s-%s%s.%s", dir, code, div, num, ext)
        end,
      })

      -- Clearer titles in the top bar of each CompetiTest pane
      local pretty = {
        tc = "Testcases",
        si = "Input (stdin)",
        so = "Your Output (stdout)",
        eo = "Expected Output",
        se = "Errors (stderr)",
      }
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        callback = function(ev)
          local ok, t = pcall(vim.api.nvim_buf_get_var, ev.buf, "competitest_title")
          if ok and type(t) == "string" then
            vim.wo.winbar = "🧪 CompetiTest — " .. (pretty[t] or t)
          end
        end,
      })
    end,
  },
}
