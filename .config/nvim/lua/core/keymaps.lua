local function map(mode, shortcut, command)
  vim.keymap.set(mode, shortcut, command, { noremap = true, silent = true })
end

local function nmap(shortcut, command)
  map("n", shortcut, command)
end

local function vmap(shortcut, command)
  map("v", shortcut, command)
end

local function imap(shortcut, command)
  map("i", shortcut, command)
end

local function cmap(shortcut, command)
  map("c", shortcut, command)
end

-- LEADER MAPPINGS

vim.g.mapleader = " "

-- use esc to also clear the highlight
nmap("<esc>", ":nohlsearch<cr><esc>")

-- write shell cmd to file
map({ "n", "v" }, "<leader>S", ":.!bash<CR>")

-- tagbar screen
nmap("<leader>tt", ":TagbarToggle<CR>")

-- dictionaries
--  TODO: write telescope plugin to do that
nmap("<leader>we", ":execute '!dict -d wn ' . shellescape(expand('<cword>')) . ' | head -n 40'<CR>")
nmap("<leader>wt", ":execute '!dict -d moby-thesaurus ' . shellescape(expand('<cword>')) . ' | head -n 40'<CR>")
nmap("<leader>wp", ":execute '!dict -d fd-por-eng ' . shellescape(expand('<cword>')) . ' | head -n 40'<CR>")
nmap("<leader>wd", ":execute '!dict -d fd-deu-eng ' . shellescape(expand('<cword>')) . ' | head -n 40'<CR>")

-- MAJOR MAPPINGS

-- common sense
map({ "n", "v" }, "H", "^")
map({ "n", "v" }, "L", "g_")
map({ "n", "v" }, "H", "^")
map({ "n", "v" }, "L", "g_")

-- u: undo, U: redo
map("n", "U", "<c-r>")

-- movement in splits
nmap("<c-k>", "<c-w><up>")
nmap("<c-j>", "<c-w><down>")
nmap("<c-h>", "<c-w><left>")
nmap("<c-l>", "<c-w><right>")

-- re-size windows
nmap("<Up>", "<c-w>+")
nmap("<Down>", "<c-w>-")
nmap("<right>", "<c-w><")
nmap("<left>", "<c-w>>")

-- better navigation
nmap("]t", ":w|:tabnext<cr>")
nmap("[t", ":w|:tabprev<cr>")

nmap("]b", ":w|:bnext<cr>")
nmap("[b", ":w|:bprev<cr>")

nmap("]c", "g,")
nmap("[c", "g;")

nmap("]j", "<c-i>")
nmap("[j", "<c-o>")

-- close buffer
nmap("<leader>x", ":bdelete<CR>")

-- deplete to void register multiple times
vmap("<leader>d", '"_d')

-- pasting multiple times
nmap("gp", '"0p')
nmap("gP", '"0P')
vmap("gp", '"0p')
vmap("gP", '"0P')

-- MINOR MAPPINGS

-- Past from + register in insert mode
imap("<c-r>", "<c-r>+")

-- visual selection in fold
nmap("viz", "v[zo]z$")
nmap("vaz", "v[zo]z$")

-- move visual selection up/down
vmap("J", ":m '>+1<CR>gv=gv")
vmap("K", ":m '<-2<CR>gv=gv")

-- bash like in ex mode
cmap("<C-a>", "<home>")
cmap("<C-e>", "<end>")

-- don't move cursor when using J
nmap("J", "mzJ`z")

-- undo breaks on punctuation
imap(",", ",<C-g>u")
imap(".", ".<C-g>u")

-- save (similar to ZZ, ZQ)
nmap("ZS", ":w<CR>")

-- keep selection after indenting
vmap("<", "<gv")
vmap(">", ">gv")

-- better parenthesis navigation
nmap("<Tab>", "%")
vmap("<Tab>", "%")

-- swap semicolon and colon (don't use silent)
vim.keymap.set({ "n", "v", "c" }, ";", ":", { noremap = true, silent = false })

-- useless keys
map({ "n", "v" }, "M", "<NOP>")
map({ "n", "v" }, "Q", "<NOP>")
map({ "n", "v" }, "gQ", "<NOP>")
map({ "n", "v" }, ",", "<NOP>")

-- ABBREVIATIONS
vim.cmd("abbr attribtue attribute")
vim.cmd("abbr attribuet attribute")
vim.cmd("abbr cosnt const")
vim.cmd("abbr fitler filter")
vim.cmd("abbr fodl fold")
vim.cmd("abbr funciton function")
vim.cmd("abbr heigth height")
vim.cmd("abbr lenght length")
vim.cmd("abbr mpa map")
vim.cmd("abbr ragne range")
vim.cmd("abbr rigth right")
vim.cmd("abbr rnage range")
vim.cmd("abbr teh the")
vim.cmd("abbr tempalte template")
vim.cmd("abbr witdh width")
