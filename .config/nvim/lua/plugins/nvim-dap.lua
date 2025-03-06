local M = {
  "mfussenegger/nvim-dap",
  dependencies = {
    "leoluz/nvim-dap-go",
    "mfussenegger/nvim-dap-python",
    "nvim-neotest/nvim-nio",
    "rcarriga/nvim-dap-ui",
  },
  config = function()
    -- from: github.com/tjdevries/config.nvim
    local dap, dapui = require("dap"), require("dapui")

    -- setup
    dapui.setup()
    require("dap-python").setup("python")
    require("dap-go").setup()

    -- use nvim-dap events to open and close the windows automatically
    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    -- mappings
    local function nmap(shortcut, command)
      vim.keymap.set("n", shortcut, command, { noremap = true, silent = true })
    end

    nmap("<F1>", dap.continue)
    nmap("<F2>", dap.step_into)
    nmap("<F3>", dap.step_over)
    nmap("<F4>", dap.step_out)
    nmap("<F5>", dap.step_back)
    nmap("<F13>", dap.restart)
    nmap("<leader>b", dap.toggle_breakpoint)
    nmap("<space>gb", dap.run_to_cursor)
    -- eval var under cursor
    nmap("<space>?", function()
      require("dapui").eval(nil, { enter = true })
    end)
  end,
}
return M
