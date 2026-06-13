# PLAN

## Purpose
This document captures the future intent of this repository and the implementation direction.

## Quick Status
- [ ] Port .env auto-create scripting from https://github.com/EnergeticPixels/wslDebian13_setup.git
- [ ] SWF decompilation
- [ ] Terminal-based installation

## Immediate Next Task
Next priority is to bring over the scripting behavior that auto-creates `.env` from `.env.sample` when `.env` is missing.

Planned implementation notes:
1. Reuse the proven logic from the source repository and adapt paths/naming for this repo.
2. Keep behavior idempotent (do not overwrite an existing `.env`).
3. Preserve comments and defaults from `.env.sample` when generating `.env`.
4. Ensure this runs early in the entry flow so first-time setup is frictionless.
5. Document the behavior in README and PLAN status once implemented.

## Project Origin
This repository was split out from a broader Debian 13 server-build repository.
The front-end GUI installation responsibilities were extracted so they can be maintained and evolved independently here.

## What Is Already Implemented Here
The extracted front-end GUI installation scope is already implemented in this repo.

Implemented today:
- Inkscape installer flow
- GIMP installer flow
- Blender installer flow
- Audacity installer flow
- OpenShot video editor installer flow
- Shared orchestration and environment loading for front-end app installs
- DaVinci Resolve advanced/manual path documentation and script scaffolding

Current execution model:
- Main entrypoint: `begin_here.sh`
- Front-end-only entrypoint: `scripts/frontend_apps_install.sh`
- Configuration source: `.env` (based on `.env.sample`)
- Installer mode: non-interactive package installation

## Future Intent
After the `.env` auto-create port is complete, the next development direction has two primary tracks.

### 1) SWF Decompilation Capability
Goal:
Provide a practical mechanism to decompile `.swf` content back into recoverable source/assets for legacy Flash projects.

Target outcomes:
- Recover ActionScript (`.as2` and `.as3`) where available
- Recover assets (images, audio, timeline/symbol data when possible)
- Document limitations around exact `.fla` reconstruction

Important expectation:
- True, lossless `.swf` -> `.fla` round-trip is often not guaranteed.
- The project should target best-effort source/asset recovery and reproducible workflows.

Planned work:
1. Evaluate decompilation toolchain options for Linux/WSL compatibility
2. Define a standard output structure for recovered code and assets
3. Add script wrappers and logging for repeatable decompile runs
4. Add validation checks to confirm extracted artifacts are usable
5. Document known edge cases and unsupported SWF patterns

### 2) Move From .env-Driven Selection To Interactive Terminal Prompts
Goal:
Replace the current "edit `.env` first" workflow with terminal-driven question prompts that ask the user what to install.

Target outcomes:
- Interactive install selection at runtime (per app)
- Video editor choice prompt integrated into run flow
- Optional advanced branch for DaVinci-related choices
- Better UX for first-time runs

Compatibility requirement:
- Keep `.env` support for unattended/automation scenarios.
- Interactive prompts should become the default UX, while `.env` remains supported as a non-interactive mode.

Planned work:
1. Add a prompt layer before installation starts
2. Map prompt answers into the existing normalized install flags
3. Preserve existing orchestrator logic to avoid regressions
4. Add a switch to force non-interactive behavior when needed
5. Update docs with both interactive and non-interactive usage patterns

## Delivery Phases
### Phase 1: .env Auto-Create Port (Next)
- Port and adapt `.env` bootstrap scripting from the source repository
- Verify `.env` is auto-generated from `.env.sample` when missing
- Confirm existing `.env` is never overwritten
- Update README and mark checklist status

### Phase 2: Planning and Decision Records
- Select SWF decompilation tooling approach
- Define prompt UX behavior and defaults
- Document compatibility contract between interactive mode and `.env` mode

### Phase 3: Interactive Prompt Implementation
- Implement prompt-based selection flow
- Keep current install scripts as backend execution layer
- Verify behavior on Debian 13 under WSL2

### Phase 4: SWF Workflow Integration
- Implement SWF decompile wrapper scripts
- Add output conventions and validation steps
- Publish operator-facing documentation

### Phase 5: Hardening and Documentation
- Add regression checks for app install selection
- Improve troubleshooting documentation
- Refine logs and failure handling

## Definition of Done For This Direction
- Users can run the project and answer terminal questions instead of editing `.env` manually
- Existing `.env`-based execution still works for automation
- A documented SWF recovery workflow exists for `.as2`/`.as3` and assets
- Constraints and limitations around `.fla` reconstruction are clearly documented

## Notes
This PLAN describes intended direction. It does not claim that SWF decompilation tooling or interactive prompts are fully implemented yet.
