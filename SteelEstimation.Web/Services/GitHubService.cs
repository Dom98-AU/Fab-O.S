using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.Models;

namespace SteelEstimation.Web.Services
{
    public class GitHubService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;
        private readonly ILogger<GitHubService> _logger;
        private readonly string _repoOwner = "Dom98-AU";
        private readonly string _repoName = "Steel-Estimation-Platform";

        public GitHubService(HttpClient httpClient, IConfiguration configuration, ILogger<GitHubService> logger)
        {
            _httpClient = httpClient;
            _configuration = configuration;
            _logger = logger;
            
            // Configure GitHub API
            _httpClient.BaseAddress = new Uri("https://api.github.com/");
            _httpClient.DefaultRequestHeaders.Add("Accept", "application/vnd.github.v3+json");
            _httpClient.DefaultRequestHeaders.UserAgent.Add(
                new ProductInfoHeaderValue("SteelEstimation", "1.0"));
            
            // Add GitHub token if configured
            var token = _configuration["GitHub:AccessToken"];
            if (!string.IsNullOrEmpty(token))
            {
                _httpClient.DefaultRequestHeaders.Authorization = 
                    new AuthenticationHeaderValue("Bearer", token);
            }
        }

        public async Task<List<GitHubCommit>> GetCommitsAsync(string branch, int count = 10)
        {
            try
            {
                var response = await _httpClient.GetAsync(
                    $"repos/{_repoOwner}/{_repoName}/commits?sha={branch}&per_page={count}");
                
                if (response.IsSuccessStatusCode)
                {
                    var json = await response.Content.ReadAsStringAsync();
                    using var document = JsonDocument.Parse(json);
                    var commits = document.RootElement.EnumerateArray();
                    var result = new List<GitHubCommit>();
                    
                    foreach (var c in commits)
                    {
                        result.Add(new GitHubCommit
                        {
                            Sha = c.GetProperty("sha").GetString() ?? string.Empty,
                            Message = c.GetProperty("commit").GetProperty("message").GetString() ?? string.Empty,
                            Author = c.GetProperty("commit").GetProperty("author").GetProperty("name").GetString() ?? string.Empty,
                            Date = c.GetProperty("commit").GetProperty("author").GetProperty("date").GetDateTime(),
                            Url = c.GetProperty("html_url").GetString() ?? string.Empty
                        });
                    }
                    return result;
                }
                
                _logger.LogWarning($"Failed to get commits from GitHub: {response.StatusCode}");
                return new List<GitHubCommit>();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching commits from GitHub");
                return new List<GitHubCommit>();
            }
        }

        public async Task<List<GitHubCommit>> GetCommitsBetweenAsync(string baseBranch, string headBranch)
        {
            try
            {
                var response = await _httpClient.GetAsync(
                    $"repos/{_repoOwner}/{_repoName}/compare/{baseBranch}...{headBranch}");
                
                if (response.IsSuccessStatusCode)
                {
                    var json = await response.Content.ReadAsStringAsync();
                    using var document = JsonDocument.Parse(json);
                    var root = document.RootElement;
                    var result = new List<GitHubCommit>();
                    
                    if (root.TryGetProperty("commits", out var commitsElement))
                    {
                        foreach (var c in commitsElement.EnumerateArray())
                        {
                            result.Add(new GitHubCommit
                            {
                                Sha = c.GetProperty("sha").GetString() ?? string.Empty,
                                Message = c.GetProperty("commit").GetProperty("message").GetString() ?? string.Empty,
                                Author = c.GetProperty("commit").GetProperty("author").GetProperty("name").GetString() ?? string.Empty,
                                Date = c.GetProperty("commit").GetProperty("author").GetProperty("date").GetDateTime(),
                                Url = c.GetProperty("html_url").GetString() ?? string.Empty
                            });
                        }
                    }
                    return result;
                }
                
                _logger.LogWarning($"Failed to compare branches on GitHub: {response.StatusCode}");
                return new List<GitHubCommit>();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error comparing branches on GitHub");
                return new List<GitHubCommit>();
            }
        }

        public async Task<string> GetLatestCommitHashAsync(string branch)
        {
            try
            {
                var response = await _httpClient.GetAsync(
                    $"repos/{_repoOwner}/{_repoName}/commits/{branch}");
                
                if (response.IsSuccessStatusCode)
                {
                    var json = await response.Content.ReadAsStringAsync();
                    using var document = JsonDocument.Parse(json);
                    var root = document.RootElement;
                    return root.TryGetProperty("sha", out var sha) ? sha.GetString() ?? string.Empty : string.Empty;
                }
                
                return string.Empty;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching latest commit hash");
                return string.Empty;
            }
        }

        public Task<string> GetCurrentBranchAsync()
        {
            // In a real implementation, this would check the deployed version
            // For now, we'll assume production is on 'master' and staging on 'develop'
            var environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
            return Task.FromResult(environment == "Production" ? "master" : "develop");
        }
    }
}