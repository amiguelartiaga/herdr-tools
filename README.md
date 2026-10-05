# herdr-tools

Small helpers around [herdr](https://herdr.dev), the terminal workspace manager.

| Tool         | What it does                                                               |
|--------------|----------------------------------------------------------------------------|
| `herdr-here` | Open a local terminal on the machine and directory herdr is showing        |
| `herdr-view` | Show PNG, JPG, WEBP, GIF or PDF files inline in a herdr pane, also over SSH |
| `v`          | Short front end: `v` lists images/PDFs in the directory, `v 2` views one   |

## Install

```bash
./install.sh                 # symlinks bin/* into ~/.local/bin
./install.sh host1 host2     # copies herdr-view and v to those hosts' ~/.local/bin
```

Hyprland bindings (Omarchy, `~/.config/hypr/bindings.lua`), then `hyprctl reload`:

```lua
o.bind("SUPER + SHIFT + H", "Terminal on herdr machine/dir", "~/.local/bin/herdr-here")
o.bind("SUPER + SHIFT + K", "Kitty on herdr machine/dir", "~/.local/bin/herdr-here -t kitty")
```

## herdr-here

If the selected herdr machine is a remote host, it opens an `ssh -t` session
that `cd`s into the focused pane's directory. If Local is selected, it opens a
terminal in that directory. Bound to a key, it lets you start a second tool
next to whatever herdr pane you are looking at.

It replaces the old window-title trick (parse `user@host /path` from the
terminal title) with herdr's own CLI, so it also works for agent panes whose
title is a conversation name rather than a path.

How it works:

1. `herdr machine list --json` reports which saved machine is `selected`.
   None selected means Local.
2. `herdr [--machine LABEL] pane list` reports every pane with `focused` and
   `cwd`.
3. A terminal is launched: the Omarchy/xdg default terminal, or one you choose.

```
herdr-here [options]
  -m, --machine LABEL   use this saved machine instead of the selected one
  -l, --local           force the local herdr session
  -t, --terminal NAME   default | kitty | foot | alacritty | ghostty
  -v, --view [FILE]     after opening, show FILE (default: newest png/jpg/webp/gif/pdf
                        in that directory) with herdr-view, then leave a shell
  -n, --dry-run         print the command instead of running it
```

`--view` opens the terminal and immediately shows the newest image or PDF in
that directory. The usual workflow is simpler: Super+Shift+K opens kitty on the
machine and directory, then type `v` there.

| Variable                  | Default        | Meaning                                  |
|---------------------------|----------------|------------------------------------------|
| `HERDR_HERE_TERMINAL`     | `default`      | terminal, same values as `--terminal`    |
| `HERDR_HERE_SSH_OPTS`     | `-X`           | extra ssh options (set empty to disable) |
| `HERDR_HERE_REMOTE_SHELL` | `exec bash -l` | command run on the remote after `cd`     |

The saved machine's SSH target is used as-is, so ports and users come from
`~/.ssh/config`. Requires herdr 0.9.x with saved machines, `jq`, and
`xdg-terminal-exec` (ships with Omarchy) or one of the supported terminals.

Limitation: the selected machine is read from herdr's client state, so with two
herdr windows showing different machines it follows the most recent selection.

## v

The everyday command, meant for the kitty side terminal:

```
v                 list images/PDFs in the current directory, newest first, numbered
v N               view entry N of that list
v FILE...         view the given files
v -p 3 FILE.pdf   options are passed through to herdr-view
v -i FILE.pdf     page through a PDF inline even if tdf is installed
v -a FILE.pdf     dump all pages inline, one after another
```

Images go through herdr-view. PDFs open in [tdf](https://github.com/itsjunetime/tdf)
when it is installed, so you can scroll pages. Otherwise v pages through them
itself: Enter shows the next page, `p` the previous one, a number jumps to that
page, `a` dumps the rest and `q` quits. Each page is rendered on demand, so
large PDFs open instantly.

## herdr-view

```
herdr-view [options] FILE...
  -p, --page N | A-B   PDF page or page range (default: 1)
  -r, --dpi DPI        PDF rasterisation resolution (default: 110)
  -w, --width COLS     max width in terminal columns (default: terminal width)
  -H, --height ROWS    max height in terminal rows (default: terminal height - 2)
  -q, --quiet          no file name caption
  --pages              print the page count of each PDF and exit
```

It emits the Kitty graphics protocol. herdr parses it on the server side and
draws the image in the outer terminal, including for remote panes, so the
script only needs to exist on the machine where the file lives.

Requirements:

- The outer terminal must support Kitty graphics: kitty, ghostty or wezterm.
  foot and alacritty do not, and herdr does not forward sixel.
- Python 3. PNG needs nothing else.
- JPG/WEBP/GIF need Pillow, or ImageMagick, or ffmpeg.
- PDF needs `pdftoppm` (poppler), or PyMuPDF, or ghostscript, or ImageMagick.

Examples:

```bash
herdr-view plot.png
herdr-view -p 3 paper.pdf          # page 3
herdr-view -p 1-4 -r 80 slides.pdf # pages 1 to 4, smaller
herdr-view -w 60 *.jpg             # at most 60 columns wide
```
