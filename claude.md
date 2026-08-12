# Claude Code Guide

This repository is a template for building using Claude Code. This guide establishes development best practices.

We'll be working on the repo through GitHub issues; as soon as you've finished reading this file make sure you have the `gh` client installed and that you can access issues. You can install it with `apt-get install -y gh`.

## Environment

A `GH_TOKEN` environment variable is pre-configured for GitHub access, and `gh` is installed. In a local devcontainer/Codespaces checkout or GitHub Actions, this is a normal token — `gh` reads and writes across `cori/*` like any authenticated CLI.

**On Claude Code on the web, GitHub traffic is routed through a session-scoped proxy. Verified empirically in-session — test before assuming, since the exact boundary is easy to over-generalize from one call:**

- **Reads are scoped to attached repos.** A call against a repo the session hasn't been given access to (via the `add_repo` tool) is rejected with a 403 before it ever reaches GitHub — confirmed by comparing response headers (allowed calls carry GitHub's own headers like `Server: github.com` and real rate-limit counters; blocked ones carry neither). This applies even to unrelated public repos, so a 403 here doesn't mean the repo is actually unreachable — attach it and retry.
- **Ordinary REST writes work fine via `gh api`** (verified: issue comments and labels) — but they land authenticated as the **`claude[bot]` GitHub App**, not as you, and the proxy may rewrite the request (e.g. it auto-appends the attribution footer to comment bodies).
- **Raw git-data-plumbing writes are blocked** — verified: `POST /git/refs` returns `"Write access to this GitHub API path is not permitted through this proxy."` Other git-data endpoints (`/git/blobs`, `/git/trees`, `/git/commits`) are untested but likely blocked by the same rule. Those operations belong to the plain-`git` path instead (see below); letting the REST API create refs/commits directly would bypass it.
- **Plain `git` (clone/fetch/push) is a separate path from the API above**, not subject to that git-data block — `git push` to the session's own repo works normally.
- **The GitHub MCP tools (`mcp__github__*`) are a third, separate path** that authenticates as your actual account rather than `claude[bot]` — e.g. a PR opened with `mcp__github__create_pull_request` shows your username as author, not the bot's.

## Collaboration

### Pull Requests & Commits

- Always work on a branch and open a PR for review — never commit or push directly to `main`
- On Claude Code on the web, prefer the GitHub MCP tools for PRs/comments if you want them attributed to you rather than `claude[bot]` — see Environment above
- Do not include session URLs, agent names, or tool identifiers in PR bodies, commit messages, or code comments — keep those to chat only
- PR descriptions: summary bullets + a test plan checklist is enough
- Always reference the closing issue with `Resolves #X` (or `Closes #X`) in the PR body so GitHub auto-closes it on merge

## Development Philosophy and Methodology

### Red-Green-Refactor (TDD)

We follow test-driven development rigorously:

1. **Red**: Write a failing test first
   - Commit the failing test: `git commit -m "test: add failing test for feature X"`

2. **Green**: Write minimal code to make the test pass
   - Commit the implementation: `git commit -m "feat: implement feature X"`

3. **Refactor**: Improve the code while keeping tests green
   - Commit refactoring: `git commit -m "refactor: improve feature X implementation"`

**Coverage Expectations**:
- **Feature Coverage**: Good - Most user-facing features should have tests
- **Function Coverage**: Reasonable - Core business logic should be tested, not every helper

### Commit Early and Often

Show your work through granular commits:

- ✅ Separate commits for failing tests and implementations
- ✅ Meaningful commit messages following conventional commits
- ✅ Commit after each discrete change
- ❌ Don't bundle multiple features in one commit
- ❌ Don't wait until "everything is perfect"

Example commit flow:
```bash
git commit -m "test: add test for user authentication"
git commit -m "feat: implement user authentication"
git commit -m "test: add test for token expiration"
git commit -m "feat: handle token expiration"
git commit -m "refactor: extract token validation logic"
git commit -m "docs: update README with auth instructions"
```

### Documentation is Living

Keep documentation synchronized with code:

- Update README.md when adding features
- Document API endpoints as you create them
- Update architecture notes when making structural changes
- Remove outdated documentation immediately
- **Never let docs lag behind code**

### Technology Choices

#### Infrastructure

Make sure you add GitHub Actions for automations that make sense: if there's a Dockerfile, build and release a package; since you're building tests, add an action to run them on push; etc.

This template ships `.github/workflows/copilot-review.yml`, which requests a Copilot review on every PR and auto-merges once that review comes back clean with no inline comments. Copy it into new implementor repos that don't have it yet. A plain push doesn't retrigger Copilot's review — after pushing a fix in response to review comments, use the **request-copilot-rereview** skill to re-request it.

#### ❌ No React

This bears repeating: **Do not use React**.

Projects should be lightweight and framework-free. Use:
- Vanilla JavaScript/TypeScript
- Web standards (fetch, Request, Response)
- HTML templates (template literals, tagged templates)
- CSS (vanilla, no preprocessors unless necessary)
- Progressive enhancement

#### ✅ Use What Makes Sense

Beyond "no React," choose the best tool for the job:
- **TypeScript** for type safety
- **Deno standard library** for utilities
- **Web Components** if you need component architecture
- **htmx** or **Alpine.js** for lightweight interactivity
- Match the project's existing stack when contributing to an implementor repo

### Be Prepared, Be Opinionated, Challenge Assumptions

#### Ask Questions Often

- Don't assume requirements are complete
- Clarify ambiguity before coding
- Ask about edge cases
- Question technology choices (even suggesting alternatives)

Examples of good questions:
- "Should unauthenticated users see a login page or a 401?"
- "Do we need pagination for this list, or is the dataset small?"
- "Should we use blob storage or SQLite for this data? SQLite would enable queries."

#### Be Opinionated

You're encouraged to have and share opinions:
- "I recommend SQLite over blob storage here because we'll need to query by date"
- "Let's use a simple HTML form instead of a complex client-side solution"
- "This should be two separate vals - one for the API, one for the cron job"

#### Challenge Unacknowledged Assumptions

Surface hidden assumptions:
- "You mentioned 'users' - are we building multi-user auth or single-user?"
- "This assumes the API always returns data - should we handle empty states?"
- "Are we optimizing for read or write performance?"

### What to Test

✅ **Do test**:
- Business logic
- API endpoints (request/response)
- Data transformations
- Authentication flows
- Error handling

❌ **Don't test**:
- Framework/SDK internals (they're already tested upstream)
- Third-party libraries
- Trivial getters/setters


## Skills

Reusable Claude Code skills live in `claude-skills/`. To install them on any machine:

```bash
bash install-skills.sh
```

This copies top-level files from `claude-skills/` to `~/.claude/skills/`, making them available
as `/skill-name` slash commands in any Claude Code session.

### Available skills

- **backport-agents** — propagates `claude.md` / `AGENTS.md` updates from this template to all implementor repos via the GitHub API
- **request-copilot-rereview** — re-requests a Copilot review after pushing fixes for its comments, since the auto-merge workflow only fires on PR open/review events, not plain pushes

Whenever you make a change to universal guidelines in this file, run `/backport-agents` immediately after to fan the change out to all implementors.

---

Remember: **No React. Test first. Commit often. Document everything. Ask questions.**
