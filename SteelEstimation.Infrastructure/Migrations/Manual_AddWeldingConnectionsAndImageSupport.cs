using Microsoft.EntityFrameworkCore.Migrations;
using System;

namespace SteelEstimation.Infrastructure.Migrations
{
    /// <summary>
    /// Manual migration file for adding welding connections, image support, and worksheet change tracking
    /// To apply: dotnet ef migrations add AddWeldingConnectionsAndImageSupport
    /// </summary>
    public partial class AddWeldingConnectionsAndImageSupport : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Create WeldingConnections table
            migrationBuilder.CreateTable(
                name: "WeldingConnections",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Category = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    DefaultAssembleFitTack = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    DefaultWeld = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    DefaultWeldCheck = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    DisplayOrder = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    ModifiedDate = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WeldingConnections", x => x.Id);
                });

            // Create ImageUploads table
            migrationBuilder.CreateTable(
                name: "ImageUploads",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FileName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    OriginalFileName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    FilePath = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    ThumbnailPath = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    FileSize = table.Column<long>(type: "bigint", nullable: false),
                    ContentType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Width = table.Column<int>(type: "int", nullable: true),
                    Height = table.Column<int>(type: "int", nullable: true),
                    WeldingItemId = table.Column<int>(type: "int", nullable: true),
                    UploadedByUserId = table.Column<int>(type: "int", nullable: true),
                    UploadedDate = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ImageUploads", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ImageUploads_WeldingItems",
                        column: x => x.WeldingItemId,
                        principalTable: "WeldingItems",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ImageUploads_Users",
                        column: x => x.UploadedByUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            // Create WorksheetChanges table
            migrationBuilder.CreateTable(
                name: "WorksheetChanges",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PackageWorksheetId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: true),
                    ChangeType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    EntityType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    EntityId = table.Column<int>(type: "int", nullable: false),
                    OldValues = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    NewValues = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    IsUndone = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    Timestamp = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WorksheetChanges", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WorksheetChanges_PackageWorksheets",
                        column: x => x.PackageWorksheetId,
                        principalTable: "PackageWorksheets",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_WorksheetChanges_Users",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            // Create PackageWeldingConnections table
            migrationBuilder.CreateTable(
                name: "PackageWeldingConnections",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PackageId = table.Column<int>(type: "int", nullable: false),
                    WeldingConnectionId = table.Column<int>(type: "int", nullable: false),
                    OverrideAssembleFitTack = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    OverrideWeld = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    OverrideWeldCheck = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    ModifiedDate = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PackageWeldingConnections", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PackageWeldingConnections_Packages",
                        column: x => x.PackageId,
                        principalTable: "Packages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PackageWeldingConnections_WeldingConnections",
                        column: x => x.WeldingConnectionId,
                        principalTable: "WeldingConnections",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            // Add WeldingConnectionId to WeldingItems
            migrationBuilder.AddColumn<int>(
                name: "WeldingConnectionId",
                table: "WeldingItems",
                type: "int",
                nullable: true);

            // Change time fields from int to decimal
            migrationBuilder.AlterColumn<decimal>(
                name: "AssembleFitTack",
                table: "WeldingItems",
                type: "decimal(18,2)",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<decimal>(
                name: "Weld",
                table: "WeldingItems",
                type: "decimal(18,2)",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<decimal>(
                name: "WeldCheck",
                table: "WeldingItems",
                type: "decimal(18,2)",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int");

            // Add Description to Projects
            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "Projects",
                type: "nvarchar(max)",
                nullable: true);

            // Create indexes
            migrationBuilder.CreateIndex(
                name: "IX_WeldingConnections_Category",
                table: "WeldingConnections",
                column: "Category");

            migrationBuilder.CreateIndex(
                name: "IX_ImageUploads_WeldingItemId",
                table: "ImageUploads",
                column: "WeldingItemId");

            migrationBuilder.CreateIndex(
                name: "IX_ImageUploads_UploadedByUserId",
                table: "ImageUploads",
                column: "UploadedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_WorksheetChanges_PackageWorksheetId",
                table: "WorksheetChanges",
                column: "PackageWorksheetId");

            migrationBuilder.CreateIndex(
                name: "IX_WorksheetChanges_UserId",
                table: "WorksheetChanges",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_PackageWeldingConnections_PackageId",
                table: "PackageWeldingConnections",
                column: "PackageId");

            migrationBuilder.CreateIndex(
                name: "IX_PackageWeldingConnections_WeldingConnectionId",
                table: "PackageWeldingConnections",
                column: "WeldingConnectionId");

            migrationBuilder.CreateIndex(
                name: "IX_WeldingItems_WeldingConnectionId",
                table: "WeldingItems",
                column: "WeldingConnectionId");

            // Add foreign key for WeldingConnectionId
            migrationBuilder.AddForeignKey(
                name: "FK_WeldingItems_WeldingConnections",
                table: "WeldingItems",
                column: "WeldingConnectionId",
                principalTable: "WeldingConnections",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            // Add unique constraint for package welding connections
            migrationBuilder.CreateIndex(
                name: "UQ_PackageWeldingConnections",
                table: "PackageWeldingConnections",
                columns: new[] { "PackageId", "WeldingConnectionId" },
                unique: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Drop foreign keys
            migrationBuilder.DropForeignKey(
                name: "FK_WeldingItems_WeldingConnections",
                table: "WeldingItems");

            // Drop tables
            migrationBuilder.DropTable(
                name: "PackageWeldingConnections");

            migrationBuilder.DropTable(
                name: "WorksheetChanges");

            migrationBuilder.DropTable(
                name: "ImageUploads");

            migrationBuilder.DropTable(
                name: "WeldingConnections");

            // Drop columns
            migrationBuilder.DropColumn(
                name: "WeldingConnectionId",
                table: "WeldingItems");

            migrationBuilder.DropColumn(
                name: "Description",
                table: "Projects");

            // Revert time fields back to int
            migrationBuilder.AlterColumn<int>(
                name: "AssembleFitTack",
                table: "WeldingItems",
                type: "int",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "decimal(18,2)");

            migrationBuilder.AlterColumn<int>(
                name: "Weld",
                table: "WeldingItems",
                type: "int",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "decimal(18,2)");

            migrationBuilder.AlterColumn<int>(
                name: "WeldCheck",
                table: "WeldingItems",
                type: "int",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "decimal(18,2)");
        }
    }
}