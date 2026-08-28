.DEFAULT_GOAL := help

REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SKILLS_SOURCE := $(REPO_ROOT)/skills
SKILLS_MANAGER := $(REPO_ROOT)/scripts/manage-skill-links.sh

CODEX_SKILLS_DIR ?= $(HOME)/.agents/skills
CLAUDE_SKILLS_DIR ?= $(HOME)/.claude/skills
OPENCODE_SKILLS_DIR ?= $(HOME)/.config/opencode/skills

.PHONY: help all codex claude opencode unlink-all unlink-codex unlink-claude unlink-opencode test

help:
	@printf '%s\n' \
		'Skill symlink targets:' \
		'  make codex          Link skills for Codex' \
		'  make claude         Link skills for Claude Code' \
		'  make opencode       Link skills for OpenCode' \
		'  make all            Link skills for all three tools' \
		'  make unlink-codex   Remove repository-owned Codex links' \
		'  make unlink-claude  Remove repository-owned Claude links' \
		'  make unlink-opencode Remove repository-owned OpenCode links' \
		'  make unlink-all     Remove repository-owned links for all tools' \
		'  make test           Run the symlink manager tests' \
		'' \
		'Destination variables can be overridden on the command line.'

all: codex claude opencode

codex:
	@"$(SKILLS_MANAGER)" link "$(SKILLS_SOURCE)" "$(CODEX_SKILLS_DIR)"

claude:
	@"$(SKILLS_MANAGER)" link "$(SKILLS_SOURCE)" "$(CLAUDE_SKILLS_DIR)"

opencode:
	@"$(SKILLS_MANAGER)" link "$(SKILLS_SOURCE)" "$(OPENCODE_SKILLS_DIR)"

unlink-all: unlink-codex unlink-claude unlink-opencode

unlink-codex:
	@"$(SKILLS_MANAGER)" unlink "$(SKILLS_SOURCE)" "$(CODEX_SKILLS_DIR)"

unlink-claude:
	@"$(SKILLS_MANAGER)" unlink "$(SKILLS_SOURCE)" "$(CLAUDE_SKILLS_DIR)"

unlink-opencode:
	@"$(SKILLS_MANAGER)" unlink "$(SKILLS_SOURCE)" "$(OPENCODE_SKILLS_DIR)"

test:
	@"$(REPO_ROOT)/tests/manage-skill-links-test.sh"
