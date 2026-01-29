## LLM Agent Workflow

### The Development Loop

```
┌─────────────────────────────────────────────────────────┐
│ 0. READ DOCS (if exist)                                 │
│    └─ macro plan / implementation log / codebase map    │
├─────────────────────────────────────────────────────────┤
│ 1. CREATE ISSUE                                         │
│    └─ gh issue create --title '<task>' \                |
|          --label '<short summary of task>'              │
├─────────────────────────────────────────────────────────┤
│ 2. CREATE BRANCH                                        │
│    └─ git checkout -b <feature/fix/docs>/<description>  │
├─────────────────────────────────────────────────────────┤
│ 3. CREATE PHASE PLAN                                    │
│    └─ plans/phase-X.X-name.md (detailed tasks, tests)   │
├─────────────────────────────────────────────────────────┤
│ 4. IMPLEMENT (TDD)                                      │
│    └─ Write tests first → code → test → review          │
├─────────────────────────────────────────────────────────┤
│ 5. COMMIT OFTEN                                         │
│    └─ Clear commit messages / smallest working commits  │
├─────────────────────────────────────────────────────────┤
│ 6. PUSH & CREATE PR                                     │
│    └─ Push when done -> Open PR → wait for human review │
├─────────────────────────────────────────────────────────┤
│ 7. UPDATE DOCS (after human approval) e.g :             │
│    ├─ implementation logs                               │
│    └─ codebase map                                      │
└─────────────────────────────────────────────────────────┘
        │                                        │
        └────────── Loop back to step 1 ─────────┘
```

NOTE : Due to sandbox proxy configuration, you need to use the -R owner/repo flag when using gh commands

### Document Maintenance Rules

### Quick Development Steps

1. Read phase requirements from a macro plan. **Have the human create one if there is none !**

**IF `task-X-plan.md` (detailed implementation plan for task X) for the current macro plan task DOESN'T EXIST:**

1. Create detailed implementation plan in `task-X-plan.md`
2. Commit with a detailed message to a branch (never to main)
3. Push branch and create PR
4. After human approval & pr merge: update docs

**IF `task-X-plan.md` for the current phase ALREADY EXISTS:**

1. Create TodoWrite list with specific subtasks and move to a branch
2. Write unit tests for core functionality first
3. Implement code, run the test suite after each new code addition
4. Verify all exit/success criteria met
5. Commit often with conventional commit messages (WHY over HOW/WHAT)
6. Push branch and create PR
7. After human approval & pr merge: update docs

### Long-Running Tasks

For any task that blocks progress (e.g., deployment, long builds):

1. **Do NOT run it yourself** - it will timeout or block progress
2. **Provide the command** to the human with clear instructions
3. **Wait for feedback** - the human will run it and report results
4. **Complete all your other independent work before handing off**
5. **Continue based on results** - adjust approach if needed

Example:

```
I've committed and pushed the changes. Please deploy by running:

    ./deploy.sh

And let me know when it's complete.
```

### Completion Protocol

- When working on a new phase/task independent of the previous one, create a new dedicated branch
- The human in the loop is responsible for reviewing your work through the PRs
- ALWAYS push to feature/fix/docs branches, NEVER directly to main
