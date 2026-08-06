-- Global Settings
vim.o.number = true
vim.o.relativenumber = false
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.hlsearch = true
vim.opt.ignorecase = true

-- Clipboard
--
-- On a headless host reached over SSH there is no X11 or Wayland selection to
-- talk to, so "unnamedplus" on its own has no provider and yanks go nowhere.
-- The fix is OSC 52: nvim emits an escape sequence, tmux (set-clipboard on)
-- forwards it, and the local terminal puts the text in the real clipboard.
--
-- Nvim >= 0.10 does this automatically when $SSH_TTY is set. Older versions
-- need it wired up by hand, and vim.base64 does not exist there either, so
-- shell out to base64(1) from coreutils.
vim.opt.clipboard = "unnamedplus"

if vim.env.SSH_TTY and vim.fn.has("nvim-0.10") == 0 then
  local function encode(text)
    if vim.base64 then
      return vim.base64.encode(text)
    end
    -- -w 0 keeps it on one line; a wrapped payload breaks the escape sequence.
    return (vim.fn.system({ "base64", "-w", "0" }, text):gsub("%s", ""))
  end

  local function copy(lines, _)
    local payload = encode(table.concat(lines, "\n"))
    -- Write to stderr: it is unbuffered and not part of any redirected stdout.
    io.stderr:write("\027]52;c;" .. payload .. "\027\\")
  end

  -- Paste over OSC 52 requires the terminal to answer, which is unreliable and
  -- a security footgun. Read back what nvim itself last yanked instead.
  local function paste()
    local reg = vim.fn.getreg('"')
    return { vim.split(reg, "\n"), vim.fn.getregtype('"') }
  end

  vim.g.clipboard = {
    name = "osc52",
    copy = { ["+"] = copy, ["*"] = copy },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end

-- Keymaps
vim.keymap.set('n', '<C-s>', '<cmd>write<cr>', {desc = 'Save'})
