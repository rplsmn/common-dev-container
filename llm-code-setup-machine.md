# LLM Code Setup: Machine + Repo (Enterprise)

## Executive Summary
Your current approach (a “golden repo” that engineers clone and then manually copy files) works for individuals but does not scale in an enterprise. The minimum viable fix is a **single-command bootstrap** that:

1. Fetches a versioned configuration bundle (from Git, an artifact registry, or internal HTTP endpoint)
2. Installs it into the right **global locations** per tool (Claude Code, Copilot CLI, Codex, OpenCode, etc.)
3. Optionally wires per-repo hooks/templates when a new repository is created

The key design principle is to split your system into:

- **Content**: opinionated prompts/instructions (md), agents, skills, commands, hook scripts
- **Distribution**: how content is delivered (installer, package, or internal MDM)
- **Activation**: how tools discover and apply it (symlinks, config files, hooks)
- **Governance**: versioning, integrity, policy, observability, and safe overrides

## What “Good” Looks Like
### Properties
- **One-liner install** for new machines (Linux/macOS/Windows)
- **Idempotent** (safe to run multiple times)
- **Versioned + pinned** (reproducible; supports rollback)
- **Auditable** (who installed what, when, from which source)
- **Minimal, stable global instruction set** (tiny but strong “constitution”)
- **Tool-specific adapters** that map the same source material into each tool’s preferred config structure
- **Separation of concerns** between “enterprise policy” and “team/project policy”

### Non-goals (initially)
- Trying to enforce everything in prompts alone
- Complex multi-step interactive installers
- Per-tool bespoke config repos that drift

## Conceptual Architecture
### 1) A Canonical Source of Truth (This Repo)
Treat this repository as the canonical “policy + tooling spec”:

- `docs/global-claude.md` (or equivalent) → the minimal global constitution
- `agents/`, `skills/`, `commands/` → reusable LLM behavior building blocks
- `bash/` → token-saving deterministic helpers (hooks, statusline, safety gates)

Add **metadata** to make automation safe:

- A `manifest.json` (or `manifest.yaml`) listing:
  - supported tools
  - install targets (paths)
  - files to copy vs symlink
  - required executables (jq, git, etc.)
  - post-install steps

This avoids “implicit knowledge” living only in READMEs.

### 2) A Thin “Adapter Layer” Per Tool
Different tools expect different config shapes; don’t fight that—embrace it:

- `adapters/claude-code/…`
- `adapters/copilot-cli/…`
- `adapters/codex/…`
- `adapters/opencode/…`
- `adapters/mistral-vibe/…`

Each adapter does two things:

1. **Maps** canonical content into tool-specific locations and filenames
2. Adds tool-specific glue (settings files, hook registration, etc.)

This is the mechanism that lets you “set up once” while still supporting many tools.

### 3) Two Install Modes: Machine + Repo
#### Machine install
Installs global defaults and shared assets into a stable location such as:

- `~/.config/company-llm/…` (Linux)
- `~/Library/Application Support/company-llm/…` (macOS)
- `%APPDATA%\\company-llm\\…` (Windows)

Then tool adapters create symlinks/copies into each tool’s expected directory.

#### Repo install
For a given repository, installs:

- `.claude/` plugin/config for Claude Code (if used)
- local `CLAUDE.md` (small) that references the global constitution + project specifics
- optional git hooks (pre-commit, commit-msg) or tool hooks

In enterprise contexts you generally want:

- **Machine-level**: baseline compliance + shared tooling
- **Repo-level**: project-specific constraints (languages, frameworks, threat model, dependency policy)

## Recommended Distribution Approaches (From “Minimum” to “Enterprise-grade”)

### Approach A (Minimum viable): Curl | Bash bootstrap that clones the repo
**What:** A single command that downloads an installer script from a stable endpoint and runs it.

Example UX:

```bash
curl -fsSL https://internal.example.com/llm/bootstrap.sh | bash
```

**How it works:**
- Script downloads a pinned release artifact or clones a specific git tag
- Copies/symlinks content into `~/.config/company-llm`
- Runs adapters for detected tools

**Pros:** Fastest path; works anywhere.
**Cons:** Security posture depends on integrity controls; curl|bash is often frowned upon.

Mitigations:
- Pin to a tag/version + verify SHA256
- Sign artifacts (cosign/sigstore, GPG)
- Host over internal TLS + restrict who can publish

### Approach B (Better): Internal package (Homebrew tap / apt repo / winget)
**What:** Ship your config bundle as a versioned package:

- macOS: Homebrew tap formula/cask
- Linux: apt/yum package
- Windows: winget/msi

**Pros:** Familiar enterprise channels; natural upgrades/rollbacks.
**Cons:** More release engineering; needs per-OS packaging.

### Approach C (Enterprise-grade): MDM/Device Management + policy enforcement
**What:** Use MDM (Jamf/Intune/etc.) to deploy:

- the bundle under a managed directory
- tool configs under managed locations
- periodic drift remediation

**Pros:** Real enforcement; least engineer toil.
**Cons:** Requires IT partnership and strong change management.

### Approach D (Developer-platform): “Repo template + bootstrap action”
**What:** Standardize repository creation:

- a company template repo includes `.claude/`, `CLAUDE.md`, and scripts
- a GitHub Action (or internal pipeline) validates required AI policy files exist

**Pros:** Ensures new repos start compliant.
**Cons:** Doesn’t solve existing repos unless you provide a migration tool.

## Activation Patterns (How Tools Should “See” the Config)

### 1) Prefer symlinks where possible
- Keeps one canonical copy
- Enables atomic updates

Fallback to copying when tools break on symlinks (common on Windows).

### 2) Keep the Global “Constitution” tiny and stable
The global file should not contain every standard. It should:

- define unbreakable rules (security, privacy, licensing, testing expectations)
- define how to discover more detailed policies
- mandate *process* (e.g., “run tests before declaring done”, “never commit secrets”, “ask when uncertain”)

Everything else should be modular and opt-in.

### 3) Layering model (strongly recommended)
Think in layers:

1. **Platform layer** (enterprise): non-negotiable constraints
2. **Org/team layer**: engineering conventions
3. **Repo layer**: project rules
4. **Session/task layer**: ephemeral instructions

This prevents the global config from becoming a dumping ground.

## Governance: Enforcement Without Overreach
Prompt files alone are not enforceable; you need guardrails in code and in CI.

### Machine-level guardrails
- Git hooks (pre-commit) for:
  - secret scanning (gitleaks)
  - forbidden files
  - license header rules
- Shell tooling wrappers that add deterministic behavior (like your statusline)

### Repo-level enforcement
- CI checks that:
  - verify presence of required policy files
  - run linters/tests
  - validate that “AI tool generated code” still meets standards

### Drift management
- A `company-llm doctor` command:
  - verifies installed version
  - checks symlink/copy integrity
  - reports deviations

## Designing the One-Liner Installer (Minimum Requirements)

### Behavior
- Detect OS + shell
- Choose install root
- Download pinned version
- Install idempotently
- Print what changed

### Suggested CLI interface
- `company-llm install --version <tag>`
- `company-llm upgrade`
- `company-llm uninstall`
- `company-llm doctor`
- `company-llm repo-init` (adds repo-local files)

### Why a small CLI is worth it
It becomes the stable contract while the underlying bundle changes. It also supports enterprise requirements: logging, version pinning, integrity checks, and a predictable UX.

## Tool-Specific Notes (High level)

### Claude Code
Claude Code supports plugins (commands/agents/hooks) and project-local `.claude/` configuration patterns (see Anthropic’s plugin structure). Your existing structure maps naturally into a “Claude Code plugin” shape, but enterprise scale is best served by:

- a global shared bundle under `~/.config/company-llm/claude-code/…`
- optional repo-local `.claude/` that references/installs the plugin

### GitHub Copilot CLI
Copilot CLI is typically less file-config-driven than Claude Code. Focus on:

- shipping reusable shell tooling and repo templates
- providing “prompt packs” that engineers can import/launch
- enforcing norms via CI and git hooks rather than hoping a prompt does it

### Codex / OpenCode / Mistral Vibe
Expect heterogeneous config locations and frequent changes. This is exactly why the adapter layer matters: it isolates churn to adapter code rather than duplicating policy content.

## Recommended Next Steps
1. **Define a manifest**: explicit install targets and supported tools.
2. **Build a single bootstrap** (Approach A): download + install + adapters.
3. **Add a small “company-llm” CLI** for upgrades/doctoring.
4. **Standardize repo init**: template + repo-init command.
5. **Add governance**: signature verification, version pinning, and CI checks.

---

## Appendix: Example one-liner patterns

### Curl | bash (internal)
```bash
curl -fsSL https://internal.example.com/company-llm/install.sh | bash -s -- --version v1.2.3
```

### Git + script (if curl is blocked)
```bash
git clone https://github.com/company/company-llm-config ~/.config/company-llm/src && ~/.config/company-llm/src/install.sh
```

### Repo bootstrap
```bash
company-llm repo-init --type service --language go
```
