
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

## DOCUMENTATION MUST STAY UP TO DATE

Every change that affects users or the project's status MUST update the documentation in the same commit / pull request. Treat stale documentation as a bug.

- **`README.md`** (repository root): the project overview, package table, quick start and status. Update it when installation, dependencies, the minimal example, the generated output or the project status changes.
- **`docs/user_guide.md`**: the complete user-facing reference. Update it whenever you add, change or remove an annotation, annotation parameter, `FieldWidget` or `Validator` value, generated file, generated class/provider/method, route, REST call, runtime widget, or default/inferred behaviour.
- **Known limitations** (in `docs/user_guide.md`): when you fix a limitation, remove its row; when you discover or introduce one, add a row with the backlog task id.
- **Backlog tasks** (`backlog/tasks`): when you finish work, tick the acceptance criteria that are met, set the status, and add implementation notes for anything left undone or moved to another task. Do not leave merged work in "To Do".
- **Package READMEs and CHANGELOGs** (`prefab_flutter*/README.md`, `CHANGELOG.md`): keep them consistent with the root README and the user guide.

Documentation describes what the code does **today**. Mention planned behaviour only with its backlog task id (e.g. "planned in PF-13").

Before finishing a task, check: does `README.md` or `docs/user_guide.md` describe anything this change made untrue or incomplete?

## PULL REQUESTS

Always open a pull request into `main` once your work is committed and pushed — do not wait to be asked. If a pull request for the branch already exists, push to it instead of opening a new one.

- Open it as a **draft** while the work is still in progress.
- Mark it **ready for review** only when the work is complete (including the documentation and backlog updates above) **and** CI is green. If CI fails, fix it and wait for a green run first.
- The description summarises the changes, lists the backlog tasks affected, and notes anything that was not verified.
- After opening the pull request, **watch it**: subscribe to its activity so CI results, reviews and comments are handled as they arrive.
- **Keep the branch up to date with `main`.** Before pushing, and whenever the pull request is reported as out of date or conflicting, fetch `origin/main` and rebase the branch onto it. Resolve any merge conflicts yourself (keeping both sides' intent, including documentation and backlog changes), re-run the affected tests, and push with `git push --force-with-lease`. Never force-push a branch you did not create.
