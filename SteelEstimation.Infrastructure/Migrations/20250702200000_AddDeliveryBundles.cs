using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SteelEstimation.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDeliveryBundles : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Create DeliveryBundles table
            migrationBuilder.CreateTable(
                name: "DeliveryBundles",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PackageId = table.Column<int>(type: "int", nullable: false),
                    BundleNumber = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    BundleName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    TotalWeight = table.Column<decimal>(type: "decimal(10,3)", precision: 10, scale: 3, nullable: false),
                    ItemCount = table.Column<int>(type: "int", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastModified = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeliveryBundles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DeliveryBundles_Packages_PackageId",
                        column: x => x.PackageId,
                        principalTable: "Packages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            // Add columns to ProcessingItems
            migrationBuilder.AddColumn<int>(
                name: "DeliveryBundleId",
                table: "ProcessingItems",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsParentInBundle",
                table: "ProcessingItems",
                type: "bit",
                nullable: false,
                defaultValue: false);

            // Create indexes
            migrationBuilder.CreateIndex(
                name: "IX_ProcessingItems_DeliveryBundleId",
                table: "ProcessingItems",
                column: "DeliveryBundleId");

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryBundles_BundleNumber",
                table: "DeliveryBundles",
                column: "BundleNumber");

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryBundles_PackageId",
                table: "DeliveryBundles",
                column: "PackageId");

            // Add foreign key
            migrationBuilder.AddForeignKey(
                name: "FK_ProcessingItems_DeliveryBundles_DeliveryBundleId",
                table: "ProcessingItems",
                column: "DeliveryBundleId",
                principalTable: "DeliveryBundles",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Drop foreign key
            migrationBuilder.DropForeignKey(
                name: "FK_ProcessingItems_DeliveryBundles_DeliveryBundleId",
                table: "ProcessingItems");

            // Drop indexes
            migrationBuilder.DropIndex(
                name: "IX_ProcessingItems_DeliveryBundleId",
                table: "ProcessingItems");

            // Drop columns
            migrationBuilder.DropColumn(
                name: "DeliveryBundleId",
                table: "ProcessingItems");

            migrationBuilder.DropColumn(
                name: "IsParentInBundle",
                table: "ProcessingItems");

            // Drop table
            migrationBuilder.DropTable(
                name: "DeliveryBundles");
        }
    }
}