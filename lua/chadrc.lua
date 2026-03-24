-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "onedark",

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

M.ui = {
  statusline = {
    -- Options: "default", "round", "block", "arrow", "minimal"
    theme = "default", 
    
    -- In v3.0, "order" determines what is visible
    order = { "mode", "file_info", "git", "%=", "lsp_msg", "diagnostics", "cursor" },
    
    -- This controls the separator icons between parts
    separator_style = "round",
  },
}

-- Keep your original require here if you need it
require "custom.init"

return M
