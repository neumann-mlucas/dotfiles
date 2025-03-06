-- enable lua plugins caching
vim.loader.enable()

local opt = vim.opt
HOME = os.getenv("HOME")

-- [[ context ]] --
opt.number = true
opt.relativenumber = true
opt.scrolloff = 4
opt.signcolumn = "yes"
opt.wrap = false

-- [[ filetypes ]] --
opt.encoding = "utf8"
opt.fileencoding = "utf8"
opt.fileformat = "unix"

-- [[ search ]] --
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = false
opt.hlsearch = true

-- [[ tabs ]] --
opt.expandtab = true
opt.shiftround = true
opt.shiftwidth = 4
opt.smarttab = true
opt.softtabstop = 4
opt.tabstop = 4

-- [[ splits ]] --
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"

-- [[ folds ]] --
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.lsp.foldexpr()"
opt.foldlevelstart = 2

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0

-- [[ backups ]] --
opt.autoread = true
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = HOME .. "/.vim/undodir//"

-- [[ display ]] --
opt.background = "dark"
opt.termguicolors = true
vim.cmd("colorscheme gruvbox")

-- [[ clipboard ]] --
opt.clipboard = "unnamed,unnamedplus"

-- [[ wildmenu ]] --
opt.path = opt.path + ".,**"
opt.wildmenu = true
opt.wildignore =
  ".git,.hg,*.o,*.a,*.class,*.mo,*.la,*.so,*.obj,*.swp,*.jpg,*.png,*.xpm,*.gif,.DS_Store,*.aux,*.out,*.toc"

-- [[ spelling ]]
opt.spell = false
opt.spelllang = { "en_us" }

-- [[ misc ]] --
opt.path = opt.path + ".,**"
opt.isfname = opt.isfname - "="
opt.lazyredraw = false
opt.cursorline = true
opt.updatetime = 100
opt.hidden = true
opt.scrolloff = 8
opt.title = true
opt.ttimeoutlen = 100
opt.virtualedit = "block"

vim.cmd("set diffopt+=linematch:60")

-- [[ filetype detection ]]
vim.g.do_filetype_lua = 1
vim.did_load_filetypes = 0

-- [[ Performance ]] --

local disabled_built_ins = {
  -- "netrw",
  "netrwPlugin",
  "netrwSettings",
  "netrwFileHandlers",
  "gzip",
  "zip",
  "zipPlugin",
  "tar",
  "tarPlugin",
  "getscript",
  "getscriptPlugin",
  "vimball",
  "vimballPlugin",
  "2html_plugin",
  "logipat",
  "rrhelper",
  "spellfile_plugin",
  "matchit",
}
for _, plugin in pairs(disabled_built_ins) do
  vim.g["loaded_" .. plugin] = 1
end
