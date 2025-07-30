using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Services;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services;

public class ImageUploadService : IImageUploadService
{
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly ILogger<ImageUploadService> _logger;
    private readonly string _uploadPath;
    private readonly long _maxFileSize;
    private readonly string[] _allowedExtensions;
    private readonly bool _generateThumbnails;
    private readonly int _thumbnailSize;

    public ImageUploadService(
        ApplicationDbContext context,
        IConfiguration configuration,
        ILogger<ImageUploadService> logger)
    {
        _context = context;
        _configuration = configuration;
        _logger = logger;
        
        // Load configuration
        _uploadPath = configuration["ImageUpload:StoragePath"] ?? "wwwroot/uploads";
        _maxFileSize = configuration.GetValue<long>("ImageUpload:MaxFileSize", 10485760); // 10MB default
        _allowedExtensions = configuration.GetSection("ImageUpload:AllowedExtensions").Get<string[]>() 
            ?? new[] { ".jpg", ".jpeg", ".png", ".webp" };
        _generateThumbnails = configuration.GetValue<bool>("ImageUpload:GenerateThumbnails", true);
        _thumbnailSize = configuration.GetValue<int>("ImageUpload:ThumbnailSize", 200);
    }

    public async Task<ImageUpload> UploadImageAsync(IFormFile file, int? weldingItemId, int? userId)
    {
        if (!IsValidImageFile(file))
        {
            throw new InvalidOperationException("Invalid image file");
        }

        var fileName = GenerateUniqueFileName(file.FileName);
        var relativePath = GetRelativePath(fileName);
        var fullPath = Path.Combine(_uploadPath, relativePath);
        
        // Ensure directory exists
        var directory = Path.GetDirectoryName(fullPath);
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }

        // Save the file
        using (var stream = new FileStream(fullPath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        // Generate thumbnail if enabled
        string? thumbnailPath = null;
        if (_generateThumbnails)
        {
            thumbnailPath = await GenerateThumbnailAsync(fullPath, fileName);
        }

        // Get image dimensions
        int? width = null, height = null;
        try
        {
            using var image = await Image.LoadAsync(fullPath);
            width = image.Width;
            height = image.Height;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to read image dimensions for {FileName}", fileName);
        }

        // Create database record
        var imageUpload = new ImageUpload
        {
            FileName = fileName,  // This is the generated unique filename
            OriginalFileName = file.FileName,  // This is the original filename from the user
            FilePath = relativePath,
            ContentType = file.ContentType,
            FileSize = file.Length,
            Width = width,
            Height = height,
            ThumbnailPath = thumbnailPath,
            WeldingItemId = weldingItemId,
            UploadedBy = userId,
            UploadedDate = DateTime.UtcNow
        };

        _context.ImageUploads.Add(imageUpload);
        await _context.SaveChangesAsync();

        return imageUpload;
    }

    public async Task<ImageUpload> UploadImageFromBase64Async(string base64Data, string fileName, int? weldingItemId, int? userId)
    {
        // Extract the actual base64 data (remove data:image/jpeg;base64, prefix if present)
        var base64 = base64Data;
        if (base64Data.Contains(','))
        {
            base64 = base64Data.Split(',')[1];
        }

        var bytes = Convert.FromBase64String(base64);
        
        // Create a temporary MemoryStream
        using var stream = new MemoryStream(bytes);
        
        // Create IFormFile from stream
        var file = new FormFile(stream, 0, bytes.Length, "file", fileName)
        {
            Headers = new HeaderDictionary(),
            ContentType = GetContentType(fileName)
        };

        return await UploadImageAsync(file, weldingItemId, userId);
    }

    public async Task<List<ImageUpload>> UploadMultipleImagesAsync(IEnumerable<IFormFile> files, int? weldingItemId, int? userId)
    {
        var uploads = new List<ImageUpload>();
        
        foreach (var file in files)
        {
            try
            {
                var upload = await UploadImageAsync(file, weldingItemId, userId);
                uploads.Add(upload);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to upload file {FileName}", file.FileName);
            }
        }

        return uploads;
    }

    public async Task DeleteImageAsync(int imageId)
    {
        var image = await _context.ImageUploads.FindAsync(imageId);
        if (image == null) return;

        // Delete physical files
        var fullPath = Path.Combine(_uploadPath, image.FilePath);
        if (File.Exists(fullPath))
        {
            File.Delete(fullPath);
        }

        if (!string.IsNullOrEmpty(image.ThumbnailPath))
        {
            var thumbnailFullPath = Path.Combine(_uploadPath, image.ThumbnailPath);
            if (File.Exists(thumbnailFullPath))
            {
                File.Delete(thumbnailFullPath);
            }
        }

        // Remove from database
        _context.ImageUploads.Remove(image);
        await _context.SaveChangesAsync();
    }

    public async Task<byte[]> GetImageBytesAsync(string filePath)
    {
        var fullPath = Path.Combine(_uploadPath, filePath);
        if (!File.Exists(fullPath))
        {
            throw new FileNotFoundException("Image not found", filePath);
        }

        return await File.ReadAllBytesAsync(fullPath);
    }

    public async Task<string> GetImageBase64Async(string filePath)
    {
        var bytes = await GetImageBytesAsync(filePath);
        return Convert.ToBase64String(bytes);
    }

    public bool IsValidImageFile(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return false;

        if (file.Length > _maxFileSize)
            return false;

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!_allowedExtensions.Contains(extension))
            return false;

        // Additional validation: check file signature
        try
        {
            using var stream = file.OpenReadStream();
            using var image = Image.Load(stream);
            return true;
        }
        catch
        {
            return false;
        }
    }

    public string GetContentType(string fileName)
    {
        var extension = Path.GetExtension(fileName).ToLowerInvariant();
        return extension switch
        {
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".webp" => "image/webp",
            ".gif" => "image/gif",
            _ => "application/octet-stream"
        };
    }

    private string GenerateUniqueFileName(string originalFileName)
    {
        var extension = Path.GetExtension(originalFileName);
        var fileName = $"{Guid.NewGuid()}{extension}";
        return fileName;
    }

    private string GetRelativePath(string fileName)
    {
        var now = DateTime.UtcNow;
        return Path.Combine(now.Year.ToString(), now.Month.ToString("00"), fileName);
    }

    private async Task<string?> GenerateThumbnailAsync(string originalPath, string fileName)
    {
        try
        {
            using var image = await Image.LoadAsync(originalPath);
            
            // Calculate thumbnail dimensions
            var width = image.Width;
            var height = image.Height;
            
            if (width > height)
            {
                height = (int)(height * ((float)_thumbnailSize / width));
                width = _thumbnailSize;
            }
            else
            {
                width = (int)(width * ((float)_thumbnailSize / height));
                height = _thumbnailSize;
            }

            // Resize image
            image.Mutate(x => x.Resize(width, height));

            // Save thumbnail
            var thumbnailFileName = $"thumb_{fileName}";
            var thumbnailRelativePath = GetRelativePath(thumbnailFileName);
            var thumbnailFullPath = Path.Combine(_uploadPath, thumbnailRelativePath);
            
            var directory = Path.GetDirectoryName(thumbnailFullPath);
            if (!string.IsNullOrEmpty(directory))
            {
                Directory.CreateDirectory(directory);
            }

            await image.SaveAsync(thumbnailFullPath);
            
            return thumbnailRelativePath;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate thumbnail for {FileName}", fileName);
            return null;
        }
    }
}