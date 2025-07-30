using Microsoft.AspNetCore.Http;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Services;

public interface IImageUploadService
{
    Task<ImageUpload> UploadImageAsync(IFormFile file, int? weldingItemId, int? userId);
    Task<ImageUpload> UploadImageFromBase64Async(string base64Data, string fileName, int? weldingItemId, int? userId);
    Task<List<ImageUpload>> UploadMultipleImagesAsync(IEnumerable<IFormFile> files, int? weldingItemId, int? userId);
    Task DeleteImageAsync(int imageId);
    Task<byte[]> GetImageBytesAsync(string filePath);
    Task<string> GetImageBase64Async(string filePath);
    bool IsValidImageFile(IFormFile file);
    string GetContentType(string fileName);
}