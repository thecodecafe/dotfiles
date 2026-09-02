.DEFAULT_GOAL := help

REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SKILLS_SOURCE := $(REPO_ROOT)/skills
SKILLS_MANAGER := $(REPO_ROOT)/scripts/manage-skill-links.sh
DOTFILE_MANAGER := $(REPO_ROOT)/scripts/manage-dotfile-link.sh
GHOSTTY_MANAGER := $(REPO_ROOT)/scripts/manage-ghostty-link.sh
NVIM_MANAGER := $(REPO_ROOT)/scripts/manage-nvim-link.sh
NVIM_LUAROCKS_INSTALLER := $(REPO_ROOT)/scripts/install-nvim-luarocks.sh
TMUX_TPM_INSTALLER := $(REPO_ROOT)/scripts/install-tmux-tpm.sh
KEY_REPEAT_SCRIPT := $(REPO_ROOT)/key-repeat/configure.sh
KEY_REPEAT_RESET_SCRIPT := $(REPO_ROOT)/key-repeat/reset.sh
TMUX_CONFIG_SOURCE ?= $(REPO_ROOT)/tmux/tmux.conf
AEROSPACE_MANAGER := $(REPO_ROOT)/scripts/manage-aerospace-link.sh
KARABINER_CONFIG_SOURCE ?= $(REPO_ROOT)/karabiner/karabiner.json

CODEX_SKILLS_DIR ?= $(HOME)/.agents/skills
CLAUDE_SKILLS_DIR ?= $(HOME)/.claude/skills
OPENCODE_SKILLS_DIR ?= $(HOME)/.config/opencode/skills
GHOSTTY_CONFIG_FILE ?= $(HOME)/.config/ghostty/config
NVIM_CONFIG_DIR ?= $(HOME)/.config/nvim
NVIM_LUAROCKS_DIR ?= $(HOME)/.local/share/nvim/lazy-rocks/hererocks
TMUX_CONFIG_FILE ?= $(HOME)/.config/tmux/tmux.conf
TMUX_TPM_DIR ?= $(HOME)/.tmux/plugins/tpm
AEROSPACE_CONFIG_FILE ?= $(HOME)/.config/aerospace/aerospace.toml
KARABINER_CONFIG_FILE ?= $(HOME)/.config/karabiner/karabiner.json

.PHONY: help all codex claude opencode ghostty aerospace karabiner nvim nvim-luarocks tmux tmux-tpm key-repeat reset-key-repeat unlink-all unlink-codex unlink-claude unlink-opencode unlink-ghostty unlink-aerospace unlink-karabiner unlink-nvim unlink-tmux test

help:
	@printf '%s\n' \
		'Skill symlink targets:' \
		'  make codex          Link skills for Codex' \
		'  make claude         Link skills for Claude Code' \
		'  make opencode       Link skills for OpenCode' \
		'  make ghostty        Link the Ghostty configuration' \
		'  make aerospace      Link the AeroSpace configuration' \
		'  make karabiner      Link the Karabiner Elements configuration' \
		'  make nvim           Link the Neovim configuration' \
		'  make nvim-luarocks  Install Neovim Lua 5.1 and LuaRocks' \
		'  make tmux           Link the tmux configuration' \
		'  make tmux-tpm       Install the tmux plugin manager' \
		'  make key-repeat     Configure macOS keyboard repetition' \
		'  make reset-key-repeat Reset macOS keyboard repetition overrides' \
		'  make all            Link all skills and dotfiles' \
		'  make unlink-codex   Remove repository-owned Codex links' \
		'  make unlink-claude  Remove repository-owned Claude links' \
		'  make unlink-opencode Remove repository-owned OpenCode links' \
		'  make unlink-ghostty Remove the repository-owned Ghostty link' \
		'  make unlink-aerospace Remove the repository-owned AeroSpace link' \
		'  make unlink-karabiner Remove the repository-owned Karabiner link' \
		'  make unlink-nvim    Remove the repository-owned Neovim link' \
		'  make unlink-tmux    Remove the repository-owned tmux link' \
		'  make unlink-all     Remove all repository-owned links' \
		'  make test           Run the link manager and config tests' \
		'' \
		'Destination variables can be overridden on the command line.'

all: codex claude opencode ghostty aerospace karabiner nvim tmux

codex:
	@"$(SKILLS_MANAGER)" link "$(SKILLS_SOURCE)" "$(CODEX_SKILLS_DIR)"

claude:
	@"$(SKILLS_MANAGER)" link "$(SKILLS_SOURCE)" "$(CLAUDE_SKILLS_DIR)"

opencode:
	@"$(SKILLS_MANAGER)" link "$(SKILLS_SOURCE)" "$(OPENCODE_SKILLS_DIR)"

ghostty:
	@"$(GHOSTTY_MANAGER)" link "$(GHOSTTY_CONFIG_FILE)"

aerospace:
	@"$(AEROSPACE_MANAGER)" link "$(AEROSPACE_CONFIG_FILE)"

karabiner:
	@"$(DOTFILE_MANAGER)" link "$(KARABINER_CONFIG_SOURCE)" "$(KARABINER_CONFIG_FILE)"

nvim:
	@"$(NVIM_MANAGER)" link "$(NVIM_CONFIG_DIR)"
	@if ! "$(NVIM_LUAROCKS_INSTALLER)" check "$(NVIM_LUAROCKS_DIR)" >/dev/null 2>&1; then \
		printf '%s\n' 'Run make nvim-luarocks to install Lua 5.1 and LuaRocks for Neovim.'; \
	fi

nvim-luarocks:
	@"$(NVIM_LUAROCKS_INSTALLER)" install "$(NVIM_LUAROCKS_DIR)"

tmux:
	@"$(DOTFILE_MANAGER)" link "$(TMUX_CONFIG_SOURCE)" "$(TMUX_CONFIG_FILE)"
	@if tmux list-sessions >/dev/null 2>&1; then tmux source-file "$(TMUX_CONFIG_FILE)"; fi
	@printf '%s\n' 'Run make tmux-tpm to install missing tmux plugins.'

tmux-tpm:
	@"$(TMUX_TPM_INSTALLER)" "$(TMUX_TPM_DIR)"
	@"$(TMUX_TPM_DIR)/bin/install_plugins"
	@if tmux list-sessions >/dev/null 2>&1; then tmux source-file "$(TMUX_CONFIG_FILE)"; fi
	@printf '%s\n' 'Tmux plugins installed; active tmux configuration reloaded when a server was running.'

key-repeat:
	@"$(KEY_REPEAT_SCRIPT)"

reset-key-repeat:
	@"$(KEY_REPEAT_RESET_SCRIPT)"

unlink-all: unlink-codex unlink-claude unlink-opencode unlink-ghostty unlink-aerospace unlink-karabiner unlink-nvim unlink-tmux

unlink-codex:
	@"$(SKILLS_MANAGER)" unlink "$(SKILLS_SOURCE)" "$(CODEX_SKILLS_DIR)"

unlink-claude:
	@"$(SKILLS_MANAGER)" unlink "$(SKILLS_SOURCE)" "$(CLAUDE_SKILLS_DIR)"

unlink-opencode:
	@"$(SKILLS_MANAGER)" unlink "$(SKILLS_SOURCE)" "$(OPENCODE_SKILLS_DIR)"

unlink-ghostty:
	@"$(GHOSTTY_MANAGER)" unlink "$(GHOSTTY_CONFIG_FILE)"

unlink-aerospace:
	@"$(AEROSPACE_MANAGER)" unlink "$(AEROSPACE_CONFIG_FILE)"

unlink-karabiner:
	@"$(DOTFILE_MANAGER)" unlink "$(KARABINER_CONFIG_SOURCE)" "$(KARABINER_CONFIG_FILE)"

unlink-nvim:
	@"$(NVIM_MANAGER)" unlink "$(NVIM_CONFIG_DIR)"

unlink-tmux:
	@"$(DOTFILE_MANAGER)" unlink "$(TMUX_CONFIG_SOURCE)" "$(TMUX_CONFIG_FILE)"

test:
	@"$(REPO_ROOT)/tests/manage-skill-links-test.sh"
	@"$(REPO_ROOT)/tests/manage-dotfile-link-test.sh"
	@"$(REPO_ROOT)/tests/manage-ghostty-link-test.sh"
	@"$(REPO_ROOT)/tests/ghostty-config-test.sh"
	@"$(REPO_ROOT)/tests/manage-aerospace-link-test.sh"
	@"$(REPO_ROOT)/tests/aerospace-config-test.sh"
	@"$(REPO_ROOT)/tests/karabiner-config-test.sh"
	@"$(REPO_ROOT)/tests/manage-nvim-link-test.sh"
	@"$(REPO_ROOT)/tests/nvim-config-test.sh"
	@"$(REPO_ROOT)/tests/install-nvim-luarocks-test.sh"
	@"$(REPO_ROOT)/tests/tmux-config-test.sh"
	@"$(REPO_ROOT)/tests/install-tmux-tpm-test.sh"
	@"$(REPO_ROOT)/tests/key-repeat-test.sh"
