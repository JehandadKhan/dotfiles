-- Contents of a freshly seeded notebook: a short cheatsheet in a markdown
-- cell, then an empty code cell to start typing in. Hydrogen format, so
-- `# %%` opens a code cell and `# %% [markdown]` a markdown one; prose in a
-- markdown cell is `# `-prefixed.
local SEED_LINES = {
  "# %% [markdown]",
  "# **Cells:** `# %%` code \194\183 `# %% [markdown]` text",
  "# **Run:** `<leader>ml` line \194\183 `<leader>mr` cell \194\183 `<leader>mv` selection",
  "# **Kernel:** `<leader>mi` init \194\183 `:MoltenInfo` status",
  "# **Output:** `<leader>mo` enter \194\183 `<leader>mh` hide \194\183 `:MoltenExportOutput` save",
  "",
  "# %%",
  "",
}

return {
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false,
    opts = {
      style = "hydrogen",
      output_extension = "auto",
      force_ft = nil,
    },
    init = function()
      -- Seeding must be registered before lazy.nvim loads plugins, so that a
      -- file named on the command line (`nvim new.ipynb`) is created before
      -- jupytext's BufReadCmd tries to read it. Registering this in config()
      -- is too late: the read already failed and printed a traceback.
      --
      -- Why not BufNewFile? jupytext.nvim registers only BufReadCmd, and
      -- Neovim fires that even when the file doesn't exist (a *Cmd event
      -- takes over the read), so BufNewFile never runs and
      -- get_ipynb_metadata() indexes the nil from io.open -> utils.lua:16.
      local function venv_bin(name)
        local venv = vim.fn.expand("~/.local/share/nvim-venv/bin/" .. name)
        if vim.fn.executable(venv) == 1 then
          return venv
        end
        return vim.fn.exepath(name) ~= "" and name or nil
      end

      local function default_kernel()
        local jupyter = venv_bin("jupyter")
        if not jupyter then
          return "python3"
        end
        local res = vim.system({ jupyter, "kernelspec", "list", "--json" }, { text = true }):wait()
        if res.code ~= 0 then
          return "python3"
        end
        local ok, decoded = pcall(vim.json.decode, res.stdout)
        if not ok or not decoded or not decoded.kernelspecs then
          return "python3"
        end
        local names = vim.tbl_keys(decoded.kernelspecs)
        table.sort(names)
        return names[1] or "python3"
      end

      local function seed_missing(path)
        path = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
        if path == "" or vim.fn.filereadable(path) == 1 then
          return
        end
        local jupytext = venv_bin("jupytext")
        if not jupytext then
          return
        end
        vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
        local kernel = default_kernel()
        local tmp = vim.fn.tempname() .. ".py"
        vim.fn.writefile(SEED_LINES, tmp)
        local res = vim.system({
          jupytext, "--to", "ipynb", "--set-kernel", kernel, tmp, "-o", path,
        }, { text = true }):wait()
        vim.fn.delete(tmp)
        if res.code == 0 then
          vim.schedule(function()
            vim.notify("new notebook (" .. kernel .. "): " .. vim.fn.fnamemodify(path, ":~:."))
          end)
        end
      end

      -- Buffers already listed at startup (`nvim new.ipynb`).
      for _, arg in ipairs(vim.fn.argv()) do
        if type(arg) == "string" and arg:match("%.ipynb$") then
          seed_missing(arg)
        end
      end

      -- ... and any opened later (`:edit new.ipynb`).
      vim.api.nvim_create_autocmd("BufAdd", {
        group = vim.api.nvim_create_augroup("jupytext-newfile", { clear = true }),
        pattern = "*.ipynb",
        callback = function(ev)
          seed_missing(ev.file)
        end,
      })
    end,
    config = function(_, opts)
      require("jupytext").setup(opts)

      -- Prefer the nvim venv's copy of a jupyter/jupytext binary, falling
      -- back to PATH. The venv is what vim.g.python3_host_prog points at,
      -- so its kernelspec search path is the one molten resolves against.
      local function venv_bin(name)
        local venv = vim.fn.expand("~/.local/share/nvim-venv/bin/" .. name)
        if vim.fn.executable(venv) == 1 then
          return venv
        end
        return vim.fn.exepath(name) ~= "" and name or nil
      end

      -- kernelspec directory names (what :MoltenInit wants) + display names.
      local function kernels()
        local jupyter = venv_bin("jupyter")
        if not jupyter then
          return {}
        end
        local res = vim.system({ jupyter, "kernelspec", "list", "--json" }, { text = true }):wait()
        if res.code ~= 0 then
          return {}
        end
        local ok, decoded = pcall(vim.json.decode, res.stdout)
        if not ok or not decoded or not decoded.kernelspecs then
          return {}
        end
        local out = {}
        for name, entry in pairs(decoded.kernelspecs) do
          table.insert(out, { name = name, display = entry.spec and entry.spec.display_name or name })
        end
        table.sort(out, function(a, b)
          return a.name < b.name
        end)
        return out
      end

      -- Write a minimal one-cell .ipynb at `path`. Returns true on success.
      --
      -- `--set-kernel` is load-bearing: without it jupytext writes a notebook
      -- with no `kernelspec` in its metadata, and jupytext.nvim's
      -- get_ipynb_metadata() indexes `metadata.kernelspec.language`
      -- unconditionally (utils.lua:17) -> the BufReadCmd throws and you get an
      -- empty, unusable buffer.
      local function seed(path, kernel)
        local jupytext = venv_bin("jupytext")
        if not jupytext then
          vim.notify("jupytext not found (is ~/.local/bin on PATH?)", vim.log.levels.ERROR)
          return false
        end
        vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")

        local tmp = vim.fn.tempname() .. ".py"
        vim.fn.writefile(SEED_LINES, tmp)
        local res = vim.system({
          jupytext, "--to", "ipynb", "--set-kernel", kernel, tmp, "-o", path,
        }, { text = true }):wait()
        vim.fn.delete(tmp)

        if res.code ~= 0 then
          vim.notify("jupytext failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
          return false
        end
        return true
      end

      -- Seed a new .ipynb and open it.
      local function create(path, kernel)
        path = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
        if not path:match("%.ipynb$") then
          path = path .. ".ipynb"
        end
        if vim.fn.filereadable(path) == 1 then
          vim.notify(path .. " already exists; opening it", vim.log.levels.WARN)
          vim.cmd.edit(vim.fn.fnameescape(path))
          return
        end
        if seed(path, kernel) then
          vim.cmd.edit(vim.fn.fnameescape(path))
          vim.notify("new notebook (" .. kernel .. "): " .. vim.fn.fnamemodify(path, ":~:."))
        end
      end

      vim.api.nvim_create_user_command("NotebookNew", function(o)
        local path, kernel = o.fargs[1], o.fargs[2]
        if not path or path == "" then
          vim.notify("usage: :NotebookNew <path> [kernel]", vim.log.levels.ERROR)
          return
        end
        if kernel then
          return create(path, kernel)
        end
        local ks = kernels()
        if #ks <= 1 then
          return create(path, ks[1] and ks[1].name or "python3")
        end
        vim.ui.select(ks, {
          prompt = "Kernel for new notebook:",
          format_item = function(k)
            return string.format("%-14s %s", k.name, k.display)
          end,
        }, function(choice)
          if choice then
            create(path, choice.name)
          end
        end)
      end, {
        nargs = "+",
        complete = "file",
        desc = "Create and open a new .ipynb (seeded with a kernelspec)",
      })

      -- Kernel name <-> display name, the mapping molten's picker doesn't show.
      vim.api.nvim_create_user_command("NotebookKernels", function()
        local ks = kernels()
        if #ks == 0 then
          vim.notify("no kernelspecs found", vim.log.levels.WARN)
          return
        end
        local lines = {}
        for _, k in ipairs(ks) do
          table.insert(lines, string.format("%-14s %s", k.name, k.display))
        end
        vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
      end, { desc = "List Jupyter kernelspec names and display names" })
    end,
  },
}
