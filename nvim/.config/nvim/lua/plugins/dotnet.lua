return {
  -- 1. Register Crashdummyy's registry so Mason can find "roslyn"
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.registries = opts.registries or {}
      vim.list_extend(opts.registries, {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      })
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "roslyn", -- C# LSP
        "netcoredbg", -- .NET debugger
        "csharpier", -- formatter
      })
    end,
  },

  -- 2. Treesitter: C# syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "c_sharp" })
    end,
  },

  -- 3. roslyn.nvim
  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    ---@type RoslynNvimConfig
    opts = {
      filewatching = "auto", -- "auto" | "roslyn" | "off"
      broad_search = false, -- true = search parent dirs for .sln
      lock_target = false, -- true = always use last selected solution
      silent = false, -- true = suppress init notifications
    },
    config = function(_, opts)
      require("roslyn").setup(opts)

      -- Language server settings are configured separately via vim.lsp.config
      -- (per the README — these are sent to the Roslyn server, not the plugin)
      vim.lsp.config("roslyn", {
        settings = {
          -- Analyze full solution, not just open files
          ["csharp|background_analysis"] = {
            dotnet_analyzer_diagnostics_scope = "fullSolution",
            dotnet_compiler_diagnostics_scope = "fullSolution",
          },

          -- Auto-add using statements, show unimported types in completions
          ["csharp|completion"] = {
            dotnet_provide_regex_completions = true,
            dotnet_show_completion_items_from_unimported_namespaces = true,
            dotnet_show_name_completion_suggestions = true,
          },

          -- Inlay hints (enabled per-buffer below via LspAttach autocmd)
          ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
            csharp_enable_inlay_hints_for_lambda_parameter_types = true,
            csharp_enable_inlay_hints_for_types = true,
            dotnet_enable_inlay_hints_for_parameters = true,
            dotnet_enable_inlay_hints_for_object_creation_parameters = true,
            dotnet_enable_inlay_hints_for_other_parameters = true,
            dotnet_enable_inlay_hints_for_indexer_parameters = true,
            dotnet_enable_inlay_hints_for_literal_parameters = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
            dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
          },

          -- Show reference/test counts above methods
          ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = true,
            dotnet_enable_tests_code_lens = true,
          },

          -- Include reference assemblies in symbol search
          ["csharp|symbol_search"] = {
            dotnet_search_reference_assemblies = true,
          },

          -- Sort using directives alphabetically on format
          ["csharp|formatting"] = {
            dotnet_organize_imports_on_format = true,
          },
        },
      })

      -- Auto-refresh code lens (required per docs: :h vim.lsp.codelens.refresh)
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
        pattern = "*.cs",
        callback = function()
          vim.lsp.codelens.refresh()
        end,
      })

      -- Enable inlay hints automatically when Roslyn attaches
      vim.api.nvim_create_autocmd("LspAttach", {
        pattern = "*.cs",
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "roslyn" then
            vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
          end
        end,
      })
    end,
  },

  -- 4. DAP: .NET debugger via netcoredbg
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      local dap = require("dap")
      local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/netcoredbg"

      dap.adapters.coreclr = {
        type = "executable",
        command = mason_bin,
        args = { "--interpreter=vscode" },
      }

      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "Launch",
          request = "launch",
          program = function()
            local cwd = vim.fn.getcwd()
            local dlls = vim.fn.glob(cwd .. "/bin/Debug/**/*.dll", true, true)
            if #dlls > 0 then
              return dlls[1]
            end
            return vim.fn.input("Path to dll: ", cwd .. "/bin/Debug/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopAtEntry = false,
        },
        {
          type = "coreclr",
          name = "Attach",
          request = "attach",
          processId = require("dap.utils").pick_process,
        },
      }
    end,
  },

  -- 5. csharpier formatter via conform
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        cs = { "csharpier" },
      },
      format_on_save = {
        timeout_ms = 2000, -- csharpier can be a bit slow on first run
        lsp_fallback = false,
      },
    },
  },
}
