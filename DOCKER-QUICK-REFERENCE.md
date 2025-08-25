# Docker Development Quick Reference

## 🚀 Quick Commands

### What Changed? → What Command?

| What You Changed | Command to Run | Time |
|-----------------|----------------|------|
| **CSS files** | None - just refresh browser | Instant |
| **JavaScript files** | None - just refresh browser | Instant |
| **Images** | None - just refresh browser | Instant |
| **HTML in .razor files** | None - just refresh browser | Instant |
| **@code blocks in .razor** | `docker-compose restart web` | ~10 sec |
| **C# files (.cs)** | `docker-compose restart web` | ~10 sec |
| **appsettings.json** | `docker-compose restart web` | ~10 sec |
| **New NuGet package** | `./rebuild.ps1` | ~2-3 min |
| **Dockerfile** | `./rebuild.ps1` | ~2-3 min |
| **docker-compose.yml** | `./rebuild.ps1` | ~2-3 min |

## 📝 Essential Commands

```powershell
# Restart container (for C# changes)
docker-compose restart web

# Full rebuild (for packages/config)
./rebuild.ps1

# View logs
docker-compose logs -f web

# Stop everything
docker-compose down

# Check status
docker ps
```

## 🔧 Troubleshooting

### Changes Not Showing?

1. **CSS/JS changes not appearing**
   - Hard refresh: `Ctrl+F5` (Windows) or `Cmd+Shift+R` (Mac)
   - Clear cache: `Ctrl+Shift+Delete`

2. **C# changes not working**
   - Did you restart? `docker-compose restart web`
   - Still not working? `./rebuild.ps1`

3. **Container won't start**
   ```powershell
   docker-compose logs web  # Check error
   docker-compose down      # Clean shutdown
   ./rebuild.ps1           # Fresh rebuild
   ```

## 📁 Volume Mounts (Auto-Sync)

These folders sync automatically - no restart needed:
- `/wwwroot` - CSS, JS, images
- `/Pages` - Razor pages (HTML only)
- `/Shared` - Shared components (HTML only)
- `/Components` - Blazor components (HTML only)

**Note**: Changes to @code blocks or .cs files need restart!

## 🎯 Golden Rules

1. **Static files** (CSS/JS/images) → Just save & refresh
2. **C# code** → Save & run `docker-compose restart web`
3. **New packages** → Run `./rebuild.ps1`
4. **Weird issues** → Run `./rebuild.ps1`

## 🔗 URLs

- **App**: http://localhost:8080
- **Login**: admin@steelestimation.com / Admin@123

---
*Keep this handy! Print it or pin it to your desktop.*