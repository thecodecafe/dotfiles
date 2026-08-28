.DEFAULT_GOAL := help

REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SKILLS_SOURCE := $(REPO_ROOT)/skills
SKILLS_MANAGER := $(REPO_ROOT)/scripts/manage-skill-links.sh
DOTFILE_MANAGER := $(REPO_ROOT)/scripts/manage-dotfile-link.sh
TMUX_CONFIG_SOURCE ?= $(REPO_ROOT)/tmux/tmux.conf

CODEX_SKILLS_DIR ?= $(HOME)/.agents/skills
CLAUDE_SKILLS_DIR ?= $(HOME)/.claude/skills
OPENCODE_SKILLS_DIR ?= $(HOME)/.config/opencode/skills
TMUX_CONFIG_FILE ?= $(HOME)/.config/tmux/tmux.conf

.PHONY: help all codex claude opencode tmux unlink-all unlink-codex unlink-claude unlink-opencode unlink-tmux test

help:
	@printf '%s\n' \
		'Skill symlink targets:' \
		'  make codex          Link skills for Codex' \
		'  make claude         Link skills for Claude Code' \
		'  make opencode       Link skills for OpenCode' \
		'  make tmux           Link the tmux configuration' \
		'  make all            Link all skills and dotfiles' \
		'  make unlink-codex   Remove repository-owned Codex links' \
		'  make unlink-claude  Remove repository-owned Claude links' \
		'  make unlink-opencode Remove repository-owned OpenCode links' \
		'  make unlink-tmux    Remove the repository-owned tmux link' \
		'  make unlink-all     Remove all repository-owned links' \
		'  make test           Run the link manager and config tests' \
		'' \
		'Destination variables can be overridden on the command line.'

all: codex claude opencode tmux

codex:
	@"$(SKILLS_MANAGER)" link "$(SKILLS_SOURCE)" "$(CODEX_SKILLS_DIR)"

claude:
	@"$(SKILLS_MANAGER)" link "$(SKILLS_SOURCE)" "$(CLAUDE_SKILLS_DIR)"

opencode:
	@"$(SKILLS_MANAGER)" link "$(SKILLS_SOURCE)" "$(OPENCODE_SKILLS_DIR)"

tmux:
	@"$(DOTFILE_MANAGER)" link "$(TMUX_CONFIG_SOURCE)" "$(TMUX_CONFIG_FILE)"

unlink-all: unlink-codex unlink-claude unlink-opencode unlink-tmux

unlink-codex:
	@"$(SKILLS_MANAGER)" unlink "$(SKILLS_SOURCE)" "$(CODEX_SKILLS_DIR)"

unlink-claude:
	@"$(SKILLS_MANAGER)" unlink "$(SKILLS_SOURCE)" "$(CLAUDE_SKILLS_DIR)"

unlink-opencode:
	@"$(SKILLS_MANAGER)" unlink "$(SKILLS_SOURCE)" "$(OPENCODE_SKILLS_DIR)"

unlink-tmux:
	@"$(DOTFILE_MANAGER)" unlink "$(TMUX_CONFIG_SOURCE)" "$(TMUX_CONFIG_FILE)"

test:
	@"$(REPO_ROOT)/tests/manage-skill-links-test.sh"
