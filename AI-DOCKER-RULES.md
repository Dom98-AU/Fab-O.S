# 🚨 AI ASSISTANT: READ THIS FIRST! 🚨

## CRITICAL DOCKER RULES FOR STEEL ESTIMATION

### ⚠️ ALWAYS RUN `.\check-changes.ps1` FIRST!
This script will tell you EXACTLY what to do. No guessing needed!

### SIMPLE RULE:
**If you changed ANY C#, Razor, or @code blocks → RUN `.\rebuild.ps1`**

### DO NOT:
- ❌ Just restart the container for C# changes
- ❌ Assume volume mounts handle compiled code
- ❌ Try partial solutions first

### INSTEAD DO:
- ✅ Run `.\check-changes.ps1` to detect changes
- ✅ Follow what it says exactly
- ✅ For C#/Razor: ALWAYS use `.\rebuild.ps1`

### WHY?
- C# and Razor files compile to DLLs
- DLLs are cached in Docker layers
- Volume mounts DON'T update compiled DLLs
- Only a full rebuild clears the compiled cache

### QUICK REFERENCE:
```powershell
# Changed CSS/JS only?
docker-compose restart web

# Changed ANY C#/Razor?
.\rebuild.ps1

# Not sure?
.\check-changes.ps1  # This tells you!
```

## Remember: The user already knows this issue exists. They've documented it. Follow the documented process!