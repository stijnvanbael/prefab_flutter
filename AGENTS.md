
<!-- BACKLOG.MD MCP GUIDELINES START -->

<CRITICAL_INSTRUCTION>

## BACKLOG WORKFLOW INSTRUCTIONS

This project uses Backlog.md MCP for all task and project management activities.

**CRITICAL GUIDANCE**

- If your client supports MCP resources, read `backlog://workflow/overview` to understand when and how to use Backlog for this project.
- If your client only supports tools or the above request fails, call `backlog.get_backlog_instructions()` to load the tool-oriented overview. Use the `instruction` selector when you need `task-creation`, `task-execution`, or `task-finalization`.

- **First time working here?** Read the overview resource IMMEDIATELY to learn the workflow
- **Already familiar?** You should have the overview cached ("## Backlog.md Overview (MCP)")
- **When to read it**: BEFORE creating tasks, or when you're unsure whether to track work

These guides cover:
- Decision framework for when to create tasks
- Search-first workflow to avoid duplicates
- Links to detailed guides for task creation, execution, and finalization
- MCP tools reference

You MUST read the overview resource to understand the complete workflow. The information is NOT summarized here.

</CRITICAL_INSTRUCTION>

<!-- BACKLOG.MD MCP GUIDELINES END -->

## VISION AND PRINCIPLES

`docs/vision.md` holds the project's vision, guiding principles and roadmap.
When a task leaves a design choice open, choose what the principles favour
and name the principle in the pull request. If a task conflicts with a
principle, say so in the pull request instead of silently picking one.

## WORKING WITH THE BACKLOG FILES

The block above is maintained by Backlog.md; do not edit it. If the Backlog MCP
tools or resources are not available in your session (common in cloud
sessions), edit the task files in `backlog/` directly, keeping the existing
front matter and the `<!-- SECTION:... -->` / `<!-- AC:... -->` markers.

- **Statuses** are exactly `To Do`, `In Progress` or `Done`.
- **Completed tasks**: as soon as a task's status is `Done`, move its file from
  `backlog/tasks/` to `backlog/completed/` with `git mv`. Never leave a `Done`
  task in `backlog/tasks/`.
- **New task ids**: take the highest `PF-<n>` in `backlog/tasks/` *and*
  `backlog/completed/` plus one. Other branches may take the same number; if
  CI reports a duplicate id after you rebase, renumber *your* task (file name
  and `id:`), not the one already on `main`.
- **Milestones** live in `backlog/milestones/`. A task joins one with a
  `milestone: m-<n>` line in its front matter. Do not create milestones
  without being asked; the roadmap is the owner's decision.
- **Work left undone** goes into a new task (or an existing one), and the
  implementation notes of the finished task name that task id.

`tool/check_backlog.sh` checks the mechanical rules (Done tasks moved,
unique ids, Known limitations only reference open tasks, milestones exist).
CI runs it; run it yourself before every push.

## GENERATOR FEATURES

New generator behaviour goes into a feature module under
`prefab_flutter_generator/lib/src/features/<feature>/`, not into the artifact
templates in `lib/src/generators/`. Follow "Adding a feature" in
`docs/developer_guide.md`.

## AVOIDING MERGE CONFLICTS

Several agents work on backlog tasks at the same time, each on its own branch.
Most conflicts come from everyone appending to the same few lines. Follow
these rules so parallel branches touch different lines:

- **Changelogs: never edit a `CHANGELOG.md` directly.** Add one fragment file
  per task and package: `<package>/changelog.d/<task-id>.md` (e.g.
  `prefab_flutter_generator/changelog.d/PF-18.md`), containing the bullet
  points you would have added under "Unreleased", with the task id at the end
  of each bullet. Fragments are merged into `CHANGELOG.md` when releasing
  (see the publishing checklist in `docs/developer_guide.md`).
- **Tests: one test file per feature or task** (e.g.
  `test/number_input_test.dart`), not new groups appended to the large
  per-generator test files. Only change existing tests that your change makes
  wrong.
- **Documentation: change the section your feature belongs to**, not
  summaries elsewhere. Add new table rows and list items in their logical
  place rather than always at the end.
- **Snapshots: when expected snapshot files conflict, take `main`'s version,
  then regenerate with `UPDATE_SNAPSHOTS=1 dart test test/snapshots_test.dart`
  (in `prefab_flutter_generator`) and review the diff.** New features add a
  new fixture in `test/snapshots/fixtures/` instead of changing an existing
  one where possible.
- **Do not reformat or reorder code you are not changing** (including running
  a formatter over whole files that were not formatted before). Formatting
  noise causes conflicts in every parallel branch.
- **Rebase onto `origin/main` before you start, and again before every
  push** (see below). Re-run `tool/check_backlog.sh` and the affected tests
  after resolving conflicts.

## DEFINITION OF DONE

Before you mark a task `Done` or a pull request ready for review, check every
item:

1. All acceptance criteria are ticked, or the implementation notes explain
   why one is not met and which task now covers it.
2. Tests are added for the new behaviour, and the commands in
   `docs/developer_guide.md#running-tests` pass for every package you changed.
   If you change the generator, also run the example app steps (it compiles
   the generated code).
3. The matching page in `docs/user_guide/` and `README.md` describe the new behaviour; search
   them for text your change made untrue (e.g. `grep -n "planned in PF-<n>"`
   for your task id).
4. Known limitations: rows fixed by this change are removed; new limitations
   are added with an open task id.
5. A changelog fragment exists for every published package you changed.
6. The task file has status `Done`, is moved to `backlog/completed/`, and
   `tool/check_backlog.sh` passes.

## DOCUMENTATION MUST STAY UP TO DATE

Every change that affects users or the project's status MUST update the documentation in the same commit / pull request. Treat stale documentation as a bug.

- **`README.md`** (repository root): the project overview, package table, quick start and status. Update it when installation, dependencies, the minimal example, the generated output or the project status changes.
- **`docs/user_guide/`**: the complete user-facing reference, one page per topic (`docs/user_guide.md` is only the index). Change the page your feature belongs to (annotations, field widgets, validators, generated files, routes, nested resources, HTTP client, REST contract, runtime widgets) whenever you add, change or remove an annotation, annotation parameter, `FieldWidget` or `Validator` value, generated file, generated class/provider/method, route, REST call, runtime widget, or default/inferred behaviour.
- **Known limitations** (in `docs/user_guide/known-limitations.md`): when you fix a limitation, remove its row; when you discover or introduce one, add a row with the backlog task id.
- **Backlog tasks** (`backlog/tasks`): when you finish work, tick the acceptance criteria that are met, set the status, and add implementation notes for anything left undone or moved to another task. Do not leave merged work in "To Do".
- **Package READMEs and changelogs** (`prefab_flutter*/README.md`, `prefab_flutter*/changelog.d/`): keep them consistent with the root README and the user guide. Changelog entries go into fragments, see "Avoiding merge conflicts".

Documentation describes what the code does **today**. Mention planned behaviour only with its backlog task id (e.g. "planned in PF-13").

Before finishing a task, check: does `README.md` or a page in `docs/user_guide/` describe anything this change made untrue or incomplete?

## PULL REQUESTS

Always open a pull request into `main` once your work is committed and pushed — do not wait to be asked. If a pull request for the branch already exists, push to it instead of opening a new one.

- Open it as a **draft** while the work is still in progress.
- Mark it **ready for review** only when the work is complete (including the documentation and backlog updates above) **and** CI is green. If CI fails, fix it and wait for a green run first.
- The description summarises the changes, lists the backlog tasks affected, and notes anything that was not verified.
- **Follow CI on every push.** After opening the pull request and after each push, check the CI runs (not only the local tests) until they finish. If a job fails, read its logs, fix the cause (also when the failure already exists on `main`, since the pull request needs a green run) and push again. Report any failure you could not fix.
- After opening the pull request, **watch it**: subscribe to its activity so CI results, reviews and comments are handled as they arrive.
- **Keep the branch up to date with `main`.** Before pushing, and whenever the pull request is reported as out of date or conflicting, fetch `origin/main` and rebase the branch onto it. Resolve any merge conflicts yourself (keeping both sides' intent, including documentation and backlog changes), re-run the affected tests, and push with `git push --force-with-lease`. Never force-push a branch you did not create.
