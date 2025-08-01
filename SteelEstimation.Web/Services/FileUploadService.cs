using Microsoft.AspNetCore.Components.Forms;

namespace SteelEstimation.Web.Services
{
    public class FileUploadService
    {
        private readonly IWebHostEnvironment _environment;
        private readonly ILogger<FileUploadService> _logger;
        private readonly string[] _allowedImageExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
        private const long _maxFileSize = 5 * 1024 * 1024; // 5MB

        public FileUploadService(IWebHostEnvironment environment, ILogger<FileUploadService> logger)
        {
            _environment = environment;
            _logger = logger;
        }

        public async Task<(bool Success, string? FileName, string? ErrorMessage)> UploadUserAvatarAsync(IBrowserFile file, int userId)
        {
            try
            {
                // Validate file
                if (file.Size > _maxFileSize)
                {
                    return (false, null, "File size exceeds 5MB limit");
                }

                var extension = Path.GetExtension(file.Name).ToLowerInvariant();
                if (!_allowedImageExtensions.Contains(extension))
                {
                    return (false, null, "Invalid file type. Only JPG, PNG, GIF, and WebP images are allowed");
                }

                // Create upload directory
                var uploadsFolder = Path.Combine(_environment.WebRootPath, "uploads", "avatars");
                Directory.CreateDirectory(uploadsFolder);

                // Generate unique filename
                var fileName = $"user_{userId}_{Guid.NewGuid()}{extension}";
                var filePath = Path.Combine(uploadsFolder, fileName);

                // Save file
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.OpenReadStream(_maxFileSize).CopyToAsync(stream);
                }

                // Return relative path for storing in database
                var relativePath = $"/uploads/avatars/{fileName}";
                return (true, relativePath, null);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading avatar for user {UserId}", userId);
                return (false, null, "An error occurred while uploading the file");
            }
        }

        public async Task<bool> DeleteUserAvatarAsync(string avatarUrl)
        {
            try
            {
                if (string.IsNullOrEmpty(avatarUrl) || !avatarUrl.StartsWith("/uploads/avatars/"))
                {
                    return true; // Nothing to delete or external URL
                }

                var fileName = Path.GetFileName(avatarUrl);
                var filePath = Path.Combine(_environment.WebRootPath, "uploads", "avatars", fileName);

                if (File.Exists(filePath))
                {
                    File.Delete(filePath);
                }

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting avatar {AvatarUrl}", avatarUrl);
                return false;
            }
        }

        public async Task<(bool Success, List<string> FileUrls, string? ErrorMessage)> UploadMultipleImagesAsync(
            IReadOnlyList<IBrowserFile> files, string folder, string prefix)
        {
            var uploadedFiles = new List<string>();

            try
            {
                if (files.Count > 10)
                {
                    return (false, uploadedFiles, "Maximum 10 files can be uploaded at once");
                }

                var uploadsFolder = Path.Combine(_environment.WebRootPath, "uploads", folder);
                Directory.CreateDirectory(uploadsFolder);

                foreach (var file in files)
                {
                    // Validate each file
                    if (file.Size > _maxFileSize)
                    {
                        continue; // Skip files that are too large
                    }

                    var extension = Path.GetExtension(file.Name).ToLowerInvariant();
                    if (!_allowedImageExtensions.Contains(extension))
                    {
                        continue; // Skip invalid file types
                    }

                    // Generate unique filename
                    var fileName = $"{prefix}_{Guid.NewGuid()}{extension}";
                    var filePath = Path.Combine(uploadsFolder, fileName);

                    // Save file
                    using (var stream = new FileStream(filePath, FileMode.Create))
                    {
                        await file.OpenReadStream(_maxFileSize).CopyToAsync(stream);
                    }

                    var relativePath = $"/uploads/{folder}/{fileName}";
                    uploadedFiles.Add(relativePath);
                }

                return (true, uploadedFiles, null);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading multiple images");
                return (false, uploadedFiles, "An error occurred while uploading files");
            }
        }
    }
}