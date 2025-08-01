# Docker VS Code Quick Start Guide

## 1. Install Docker Extension

In VS Code:
- Press `Ctrl+Shift+X` to open Extensions
- Search for "Docker"
- Install the official Docker extension by Microsoft

## 2. Verify Docker Desktop is Running

Before using the extension, make sure Docker Desktop is running:
- Windows: Check system tray for Docker whale icon
- Should show "Docker Desktop is running"

## 3. Using the Docker Extension

### Docker View (Left Sidebar)
After installation, you'll see a Docker icon in the Activity Bar (left sidebar). Click it to see:
- **Containers** - Running and stopped containers
- **Images** - Docker images on your system
- **Registries** - Connected Docker registries
- **Networks** - Docker networks
- **Volumes** - Docker volumes

### Right-Click Actions on docker-compose.yml
1. **Right-click** on `docker-compose.yml` in the Explorer
2. Select one of these options:
   - **Compose Up** - Start all services
   - **Compose Down** - Stop all services
   - **Compose Restart** - Restart all services

## 4. Quick Start Commands

### Option A: Using Docker Extension UI
1. Click Docker icon in sidebar
2. Right-click on `docker-compose.yml` in Explorer
3. Select "Compose Up"

### Option B: Using VS Code Terminal
Press `` Ctrl+` `` to open terminal and run:
```bash
docker-compose up
```

## 5. Access the Application

Once containers are running:
- Open browser to: **http://localhost:8080**
- Login with:
  - Email: **admin@steelestimation.com**
  - Password: **Admin@123**

## 6. Common Docker Extension Features

### View Container Logs
1. In Docker view (sidebar)
2. Expand "Containers"
3. Right-click on `steel-estimation-web`
4. Select "View Logs"

### Attach to Running Container
1. Right-click on running container
2. Select "Attach Shell"
3. Now you're inside the container!

### Stop Everything
1. Right-click on `docker-compose.yml`
2. Select "Compose Down"

## 7. Useful Keyboard Shortcuts

- `Ctrl+Shift+P` → Type "Docker" to see all Docker commands
- `F1` → Same as above
- `Ctrl+` ` → Open terminal for Docker CLI commands

## 8. Quick Troubleshooting

### If containers won't start:
1. Check Docker Desktop is running
2. Check ports aren't in use:
   ```bash
   netstat -an | findstr :8080
   ```
3. Try clean restart:
   ```bash
   docker-compose down
   docker-compose up
   ```

### To see what's happening:
```bash
docker-compose logs -f
```

## 9. Making Code Changes

When you change code:
1. The container needs to be rebuilt
2. In terminal: `docker-compose down`
3. Then: `docker-compose up --build`

Or use the Docker extension:
1. Right-click container → Stop
2. Right-click docker-compose.yml → Compose Up

That's it! You're ready to develop with Docker in VS Code.