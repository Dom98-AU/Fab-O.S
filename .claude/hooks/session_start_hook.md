Please execute these steps immediately when I start a Claude Code session:

1. **Read my context file**: Open and analyze `.claude-context.md` to understand what I was last working on

2. **Get latest commit info**: Run `git log -1 --pretty=format:"%h - %s (%cr)" && echo "" && git show --name-only HEAD` and tell me:
   - What the latest commit changed
   - Which files were modified
   - What this suggests about my current work

3. **Check current status**: Run `git status --short` and `git branch --show-current` to see:
   - What branch I'm on
   - Any uncommitted changes
   - Current working state

4. **Analyze recent activity**: Run `git log --oneline -3` and identify:
   - Pattern of recent work
   - What feature/area I'm focused on
   - Progression of changes

5. **Provide startup summary**: Give me:
   - Current development focus based on context + commits
   - Immediate next steps to continue where I left off
   - Any files I should open first
   - Any potential issues to be aware of

**Project context**: This is Fab-O.S, a steel fabrication estimation platform using ASP.NET Core 8, Blazor Server, Clean Architecture, and Azure SQL Database.