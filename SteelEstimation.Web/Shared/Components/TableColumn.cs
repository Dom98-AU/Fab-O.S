using Microsoft.AspNetCore.Components;

namespace SteelEstimation.Web.Shared.Components
{
    public class TableColumn<T>
    {
        public string Field { get; set; } = "";
        public string Title { get; set; } = "";
        public bool Sortable { get; set; } = false;
        public string? Width { get; set; }
        public string? CssClass { get; set; }
        public RenderFragment<T>? Template { get; set; }
        public Func<T, object>? Value { get; set; }
    }
}