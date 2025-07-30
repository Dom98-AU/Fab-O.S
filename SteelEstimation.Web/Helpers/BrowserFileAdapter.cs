using Microsoft.AspNetCore.Components.Forms;
using Microsoft.AspNetCore.Http;

namespace SteelEstimation.Web.Helpers;

public class BrowserFileAdapter : IFormFile, IDisposable
{
    private readonly IBrowserFile _browserFile;
    private readonly Stream _stream;
    private readonly bool _ownsStream;
    private bool _disposed;

    public BrowserFileAdapter(IBrowserFile browserFile, Stream stream, bool ownsStream = true)
    {
        _browserFile = browserFile;
        _stream = stream;
        _ownsStream = ownsStream;
        
        // Log stream state at construction (commented out for production)
        // Console.WriteLine($"BrowserFileAdapter constructor - Stream type: {_stream.GetType().Name}, CanRead: {_stream.CanRead}, CanSeek: {_stream.CanSeek}, Length: {(_stream.CanSeek ? _stream.Length : -1)}, OwnsStream: {_ownsStream}");
    }

    public string ContentType => _browserFile.ContentType;
    public string ContentDisposition => $"form-data; name=\"file\"; filename=\"{_browserFile.Name}\"";
    public IHeaderDictionary Headers => new HeaderDictionary();
    public long Length => _browserFile.Size;
    public string Name => _browserFile.Name;
    public string FileName => _browserFile.Name;

    public void CopyTo(Stream target)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(BrowserFileAdapter));
        
        if (!_stream.CanRead)
            throw new InvalidOperationException($"Stream cannot be read. CanRead={_stream.CanRead}, CanSeek={_stream.CanSeek}");
            
        if (_stream.CanSeek)
        {
            _stream.Position = 0; // Reset position before copying
        }
        
        _stream.CopyTo(target);
    }

    public async Task CopyToAsync(Stream target, CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(BrowserFileAdapter));
        
        // Log stream state for debugging (commented out for production)
        // Console.WriteLine($"BrowserFileAdapter.CopyToAsync - Stream type: {_stream.GetType().Name}, CanRead: {_stream.CanRead}, CanSeek: {_stream.CanSeek}, Length: {(_stream.CanSeek ? _stream.Length : -1)}, Position: {(_stream.CanSeek ? _stream.Position : -1)}");
        
        if (!_stream.CanRead)
            throw new InvalidOperationException($"Stream cannot be read. CanRead={_stream.CanRead}, CanSeek={_stream.CanSeek}");
            
        if (_stream.CanSeek)
        {
            _stream.Position = 0; // Reset position before copying
        }
        
        await _stream.CopyToAsync(target, cancellationToken);
    }

    public Stream OpenReadStream()
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(BrowserFileAdapter));
        
        // Console.WriteLine($"BrowserFileAdapter.OpenReadStream - Stream type: {_stream.GetType().Name}, CanRead: {_stream.CanRead}, CanSeek: {_stream.CanSeek}");
        
        // If the stream is a MemoryStream, return a new independent stream
        // This prevents the original stream from being closed when the returned stream is disposed
        if (_stream is MemoryStream memoryStream && memoryStream.CanRead)
        {
            var buffer = memoryStream.ToArray();
            return new MemoryStream(buffer, false); // false = not writable, just for reading
        }
        
        // For other stream types, reset position and return
        if (_stream.CanSeek)
        {
            _stream.Position = 0;
        }
        
        return _stream;
    }
    
    public void Dispose()
    {
        if (!_disposed)
        {
            if (_ownsStream)
            {
                _stream?.Dispose();
            }
            _disposed = true;
        }
    }
}

public static class BrowserFileExtensions
{
    public static async Task<IFormFile> ToFormFileAsync(this IBrowserFile browserFile, long maxFileSize = 5 * 1024 * 1024)
    {
        // Create a memory stream to hold the file data
        var memoryStream = new MemoryStream();
        
        // Copy the browser file data to memory stream
        using (var browserFileStream = browserFile.OpenReadStream(maxFileSize))
        {
            await browserFileStream.CopyToAsync(memoryStream);
        }
        
        // Reset position for reading
        memoryStream.Position = 0;
        
        // Return the adapter with the memory stream
        // The memory stream will be owned by the adapter and disposed when it's disposed
        return new BrowserFileAdapter(browserFile, memoryStream);
    }
}