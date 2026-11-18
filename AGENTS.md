
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
