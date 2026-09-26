# Lesson 04 — Git Basics + GitHub Profile

Git saves **snapshots (commits)** of your project so you can go back, try ideas on
branches, and share code. GitHub hosts those repos online.

## 1. One-time setup

```powershell
git config --global user.name  "Arulesh"
git config --global user.email "arulesh.robotics@gmail.com"   # must match GitHub account
git config --global init.defaultBranch main
git config --global core.autocrlf true      # Windows: handles LF/CRLF line endings
```

## 2. The three areas

```
Working folder  --git add-->  Staging area  --git commit-->  Repository (history)
 (your edits)                 (next snapshot)                (saved snapshots)
```

## 3. Daily commands

```powershell
git init                        # make this folder a repo (once)
git status                      # what changed? (run this constantly)
git add file.py                 # stage one file
git add .                       # stage everything
git commit -m "Add OEE calc"    # save snapshot
git log --oneline --graph       # history
git diff                        # unstaged changes
git diff --staged               # staged changes (what will be committed)
```

**Good commit messages:** imperative, specific, one change per commit.
`Add retry to PLC read` ✅   `update` ❌   `fixed stuff` ❌

## 4. .gitignore

Files Git should never track. This repo's [`.gitignore`](../.gitignore):

```
.venv/
__pycache__/
logs/
*.log
.pytest_cache/
```

Also never commit passwords, API keys or client data. Keep them in a `.env` file and ignore it.

## 5. Undo

```powershell
git restore file.py             # discard unsaved edits in a file
git restore --staged file.py    # unstage (keep the edits)
git commit --amend -m "New msg" # fix the LAST commit (only if not pushed yet)
git revert <commit>             # new commit that undoes an old one (safe after push)
```

## 6. Branches

A branch is a parallel line of work. `main` stays working; experiments go on branches.

```powershell
git branch                      # list branches
git switch -c feature/slmp      # create + switch
# ...edit, add, commit...
git switch main                 # back to main
git merge feature/slmp          # bring the feature into main
git branch -d feature/slmp      # delete merged branch
```

```
main:      A---B-----------M
                \         /
feature/slmp:    C---D---E
```

Naming: `feature/...`, `fix/...`, `docs/...`.

## 7. Merge conflicts

If both branches changed the same lines, Git stops and marks the file:

```
<<<<<<< HEAD
ideal_rate = 100
=======
ideal_rate = 120
>>>>>>> feature/speedup
```

Fix it: edit the file to the correct final version, remove the markers, then:

```powershell
git add machine.py
git commit                      # completes the merge
```

(VS Code shows *Accept Current / Incoming / Both* buttons above each conflict.)

## 8. Remote (GitHub)

```powershell
git remote add origin https://github.com/aruleshlabs/python-refresh.git
git push -u origin main         # first push; after that just: git push
git pull                        # get changes from GitHub
git clone <url>                 # copy a repo to a new PC
```

**Always `git pull` before starting work** if you use more than one PC.
Never `git push --force` on shared branches; it overwrites other people's history.

## 9. Workflow for every project in this journey

```powershell
git switch -c feature/<thing>
# code + tests
pytest
git add .
git commit -m "Add <thing>"
git switch main
git merge feature/<thing>
git push
```

## 10. GitHub profile

A good profile is your shop window for clients:

1. **Profile photo + bio**: e.g. *"Industrial automation & AI engineer | PLC · SCADA · MySQL HA · Offline AI"*.
2. **Profile README**: create a repo named **exactly like your username** (`aruleshlabs`)
   with a `README.md`; GitHub shows it on your profile page. Put who you are, your stack,
   and links to your best repos.
3. **Pin 6 repos**: your best templates as they get finished (T1 plc-connector, T3 oee-dashboard…).
4. **Each repo**: clear README, screenshots/GIF, "how to run", description + topics.
5. **Commit regularly**; the green activity graph shows consistency.
