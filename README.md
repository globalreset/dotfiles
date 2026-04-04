# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Setup on a new machine

```bash
chezmoi init https://github.com/<you>/dotfiles.git
vim ~/.config/chezmoi/chezmoi.toml   # set machine-specific template data
chezmoi apply
```

## Day-to-day

```bash
chezmoi edit ~/.bashrc    # opens the template in $EDITOR
chezmoi diff              # preview what would change
chezmoi apply             # deploy changes to ~
chezmoi cd                # cd into the source repo for git operations
```

## Adding a new config file

```bash
# Static file (no machine-specific content)
chezmoi add ~/.config/foo/config.toml
# Creates: ~/dotfiles/dot_config/foo/config.toml

# File that needs machine-specific templating
chezmoi add --template ~/.config/foo/config.toml
# Creates: ~/dotfiles/dot_config/foo/config.toml.tmpl
# Existing values are replaced with {{ .chezmoi.* }} placeholders where
# chezmoi can auto-detect them (e.g. username, homedir). You'll need to
# manually replace other machine-specific values with your own template
# variables — see "Templatizing" below.
```

After adding, review what chezmoi created:

```bash
chezmoi source-path ~/.config/foo/config.toml   # show source file path
chezmoi cat ~/.config/foo/config.toml            # show what would be deployed
chezmoi diff                                     # full diff of pending changes
```

### Chezmoi naming conventions

Chezmoi maps source filenames to target filenames using prefixes:

| Source (in `~/dotfiles/`)         | Deployed to (`~/`)              |
|-----------------------------------|---------------------------------|
| `dot_bashrc.tmpl`                 | `.bashrc`                       |
| `dot_config/nvim/init.lua`        | `.config/nvim/init.lua`         |
| `dot_gitconfig.tmpl`              | `.gitconfig`                    |
| `private_dot_netrc`               | `.netrc` (mode 0600)            |
| `executable_dot_script.sh`        | `.script.sh` (mode 0755)        |

- `dot_` prefix becomes a leading `.`
- `.tmpl` suffix means the file is a Go template — it's rendered before deploying
- `private_` prefix sets file permissions to 0600
- `executable_` prefix sets file permissions to 0755

Full reference: https://www.chezmoi.io/reference/source-state-attributes/

## Templatizing

Templates use Go's [text/template](https://pkg.go.dev/text/template) syntax.
Machine-specific values come from `[data]` in `~/.config/chezmoi/chezmoi.toml`.

### Available template data

Inspect all current values with:

```bash
chezmoi data | less
```

This includes both chezmoi built-ins (`.chezmoi.os`, `.chezmoi.hostname`,
`.chezmoi.username`, etc.) and custom variables from your `chezmoi.toml`.

### Custom variables (chezmoi.toml)

| Variable               | Type     | Example values                                |
|------------------------|----------|-----------------------------------------------|
| `hostname_class`       | string   | `"work"`, `"personal"`, `"server"`            |
| `has_linuxbrew`        | bool     | `true`, `false`                               |
| `linuxbrew_prefix`     | string   | `"/home/linuxbrew/.linuxbrew"`                |
| `has_modules`          | bool     | `true`, `false`                               |
| `modulepath`           | string   | `"/projects/asic/user/dal_fpgabuild/modulefiles"` |
| `modules_to_load`      | []string | `["vivado", "questa"]`                        |
| `cc_override`          | string   | `"gcc-13"`, `""`                              |
| `zsh_named_dirs`       | bool     | `true`, `false`                               |
| `hostname_class`       | string   | `"work"`, `"personal"`                        |

To add a new variable, add it to `[data]` in your `chezmoi.toml`, then
reference it in templates as `{{ .variable_name }}`.

### Template syntax quick reference

**Simple value substitution:**
```
export MY_PATH={{ .some_path }}
```

**Conditional blocks:**
```
{{ if .has_linuxbrew -}}
eval "$({{ .linuxbrew_prefix }}/bin/brew shellenv)"
{{ end -}}
```

**String comparison:**
```
{{ if eq .hostname_class "work" -}}
export WORK_SPECIFIC_VAR=foo
{{ end -}}
```

**Looping over a list:**
```
{{ range .modules_to_load -}}
module load {{ . }}
{{ end -}}
```

**Chezmoi built-in variables:**
```
{{ if eq .chezmoi.os "darwin" -}}
# macOS-only config
{{ end -}}
```

**Whitespace control:** The `-` inside `{{-` or `-}}` trims adjacent whitespace/newlines, preventing blank lines in the rendered output.

### Testing a template

```bash
# Render a template file to stdout without applying
chezmoi execute-template < ~/dotfiles/dot_bashrc.tmpl

# Render a snippet interactively
echo '{{ .hostname_class }}' | chezmoi execute-template

# See what a managed file would look like after rendering
chezmoi cat ~/.bashrc
```

### Example: templatizing a new file

Say you just added `~/.config/tool/config` and need to templatize the data
directory which differs per machine.

1. Add a variable to `chezmoi.toml`:
   ```toml
   [data]
     tool_data_dir = "/data/tool"
   ```

2. Add the file as a template:
   ```bash
   chezmoi add --template ~/.config/tool/config
   ```

3. Edit the source to use the variable:
   ```bash
   chezmoi edit ~/.config/tool/config
   ```
   Replace the hardcoded path:
   ```diff
   -data_dir = /data/tool
   +data_dir = {{ .tool_data_dir }}
   ```

4. Verify and apply:
   ```bash
   chezmoi cat ~/.config/tool/config   # check rendered output
   chezmoi apply -v
   ```
