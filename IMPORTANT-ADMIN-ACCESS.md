# Admin Access Information

## Default Admin Account
After running the database setup scripts, you have access to:
- **Username**: admin
- **Password**: Admin@123

## First Time Setup
1. Deploy the application to sandbox
2. Run these SQL scripts in order:
   - `create-invites-table.sql`
   - `create-admin-user.sql`
3. Login with the admin credentials
4. Immediately:
   - Change the admin password
   - Create your personal admin account
   - Consider deactivating the default admin

## If Locked Out
Use the `emergency-admin-access.sql` script:
1. Update the email address in the script
2. Run it in Azure Portal Query Editor
3. Login with: emergency_admin / Admin@123
4. Create proper accounts and remove emergency account

## Testing Without Authentication
For development only, you can temporarily add this to Login.razor:

```csharp
// DEV ONLY - Remove before production!
if (loginModel.Username == "dev" && loginModel.Password == "dev")
{
    await AuthProvider.MarkUserAsAuthenticated("dev", "Administrator", "0", "dev@test.com");
    Navigation.NavigateTo("/", forceLoad: true);
    return;
}
```

## Security Best Practices
1. Never use default credentials in production
2. Always use strong passwords
3. Enable Azure AD SSO when possible
4. Regularly audit user accounts
5. Remove inactive users
6. Use the invite system for new users