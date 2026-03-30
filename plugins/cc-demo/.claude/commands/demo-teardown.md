# /demo-teardown — Purge Demo Workspace

Remove the demo workspace and all generated artifacts.

## Instructions

1. Resolve the workspace path:
   ```bash
   echo $DEMO_WORKSPACE
   ```
   If empty, derive it:
   ```bash
   node -e "const os=require('os'),path=require('path'); console.log(path.join(os.tmpdir(),'cc-demo'));"
   ```

2. Check that the resolved path exists — if not, print "Nothing to tear down." and exit

3. Read `{workspace}/artifacts/memory/demo-state.json` if it exists — print a summary:
   - Project name and slug
   - Which phases completed vs skipped
   - Git log: `git -C "{workspace}" log --oneline` (shows what was built)

4. Ask the user to confirm:
   > "This will permanently delete `{workspace}` and all generated code. Confirm? [y/N]"

5. On 'y' or 'yes' (case-insensitive):
   - Delete the workspace: `rm -rf "{workspace}"`
   - Print: "Workspace purged. Run /demo to start a new demo."

6. On any other response: print "Teardown cancelled." and exit

## Safety

- Never delete anything other than the resolved workspace path
- Always require explicit confirmation — never infer it from surrounding context
- No subagent delegation — this command runs directly
