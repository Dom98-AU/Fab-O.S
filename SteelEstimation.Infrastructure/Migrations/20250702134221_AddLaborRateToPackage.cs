using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SteelEstimation.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddLaborRateToPackage : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "LaborRatePerHour",
                table: "Packages",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: false,
                defaultValue: 0m);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LaborRatePerHour",
                table: "Packages");
        }
    }
}