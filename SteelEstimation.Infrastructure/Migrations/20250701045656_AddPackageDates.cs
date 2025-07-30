using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SteelEstimation.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddPackageDates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<decimal>(
                name: "WeldLength",
                table: "WeldingItems",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "decimal(18,2)");

            migrationBuilder.AddColumn<int>(
                name: "PackageWorksheetId",
                table: "WeldingItems",
                type: "int",
                nullable: true);

            migrationBuilder.AlterColumn<decimal>(
                name: "LaborRate",
                table: "Projects",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "decimal(18,2)");

            migrationBuilder.AlterColumn<decimal>(
                name: "ContingencyPercentage",
                table: "Projects",
                type: "decimal(5,2)",
                precision: 5,
                scale: 2,
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "decimal(18,2)");

            migrationBuilder.AddColumn<int>(
                name: "PackageWorksheetId",
                table: "ProcessingItems",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Packages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ProjectId = table.Column<int>(type: "int", nullable: false),
                    PackageNumber = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    PackageName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    StartDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    EndDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    EstimatedHours = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    EstimatedCost = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    ActualHours = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    ActualCost = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    CreatedBy = table.Column<int>(type: "int", nullable: true),
                    LastModifiedBy = table.Column<int>(type: "int", nullable: true),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastModified = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Packages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Packages_Projects_ProjectId",
                        column: x => x.ProjectId,
                        principalTable: "Projects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Packages_Users_CreatedBy",
                        column: x => x.CreatedBy,
                        principalTable: "Users",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Packages_Users_LastModifiedBy",
                        column: x => x.LastModifiedBy,
                        principalTable: "Users",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "PackageWorksheets",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PackageId = table.Column<int>(type: "int", nullable: false),
                    WorksheetType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    TotalHours = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    TotalCost = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    ItemCount = table.Column<int>(type: "int", nullable: false),
                    DisplayOrder = table.Column<int>(type: "int", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastModified = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PackageWorksheets", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PackageWorksheets_Packages_PackageId",
                        column: x => x.PackageId,
                        principalTable: "Packages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.UpdateData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedDate",
                value: new DateTime(2025, 7, 1, 4, 56, 56, 367, DateTimeKind.Utc).AddTicks(6467));

            migrationBuilder.UpdateData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedDate",
                value: new DateTime(2025, 7, 1, 4, 56, 56, 367, DateTimeKind.Utc).AddTicks(6473));

            migrationBuilder.UpdateData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedDate",
                value: new DateTime(2025, 7, 1, 4, 56, 56, 367, DateTimeKind.Utc).AddTicks(6475));

            migrationBuilder.UpdateData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedDate",
                value: new DateTime(2025, 7, 1, 4, 56, 56, 367, DateTimeKind.Utc).AddTicks(6477));

            migrationBuilder.UpdateData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedDate",
                value: new DateTime(2025, 7, 1, 4, 56, 56, 367, DateTimeKind.Utc).AddTicks(6478));

            migrationBuilder.CreateIndex(
                name: "IX_WeldingItems_PackageWorksheetId",
                table: "WeldingItems",
                column: "PackageWorksheetId");

            migrationBuilder.CreateIndex(
                name: "IX_ProcessingItems_PackageWorksheetId",
                table: "ProcessingItems",
                column: "PackageWorksheetId");

            migrationBuilder.CreateIndex(
                name: "IX_Packages_CreatedBy",
                table: "Packages",
                column: "CreatedBy");

            migrationBuilder.CreateIndex(
                name: "IX_Packages_IsDeleted",
                table: "Packages",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Packages_LastModifiedBy",
                table: "Packages",
                column: "LastModifiedBy");

            migrationBuilder.CreateIndex(
                name: "IX_Packages_PackageNumber",
                table: "Packages",
                column: "PackageNumber");

            migrationBuilder.CreateIndex(
                name: "IX_Packages_ProjectId",
                table: "Packages",
                column: "ProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_Packages_Status",
                table: "Packages",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_PackageWorksheets_PackageId",
                table: "PackageWorksheets",
                column: "PackageId");

            migrationBuilder.CreateIndex(
                name: "IX_PackageWorksheets_WorksheetType",
                table: "PackageWorksheets",
                column: "WorksheetType");

            migrationBuilder.AddForeignKey(
                name: "FK_ProcessingItems_PackageWorksheets_PackageWorksheetId",
                table: "ProcessingItems",
                column: "PackageWorksheetId",
                principalTable: "PackageWorksheets",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_WeldingItems_PackageWorksheets_PackageWorksheetId",
                table: "WeldingItems",
                column: "PackageWorksheetId",
                principalTable: "PackageWorksheets",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ProcessingItems_PackageWorksheets_PackageWorksheetId",
                table: "ProcessingItems");

            migrationBuilder.DropForeignKey(
                name: "FK_WeldingItems_PackageWorksheets_PackageWorksheetId",
                table: "WeldingItems");

            migrationBuilder.DropTable(
                name: "PackageWorksheets");

            migrationBuilder.DropTable(
                name: "Packages");

            migrationBuilder.DropIndex(
                name: "IX_WeldingItems_PackageWorksheetId",
                table: "WeldingItems");

            migrationBuilder.DropIndex(
                name: "IX_ProcessingItems_PackageWorksheetId",
                table: "ProcessingItems");

            migrationBuilder.DropColumn(
                name: "PackageWorksheetId",
                table: "WeldingItems");

            migrationBuilder.DropColumn(
                name: "PackageWorksheetId",
                table: "ProcessingItems");

            migrationBuilder.AlterColumn<decimal>(
                name: "WeldLength",
                table: "WeldingItems",
                type: "decimal(18,2)",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "decimal(10,2)",
                oldPrecision: 10,
                oldScale: 2);

            migrationBuilder.AlterColumn<decimal>(
                name: "LaborRate",
                table: "Projects",
                type: "decimal(18,2)",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "decimal(10,2)",
                oldPrecision: 10,
                oldScale: 2);

            migrationBuilder.AlterColumn<decimal>(
                name: "ContingencyPercentage",
                table: "Projects",
                type: "decimal(18,2)",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "decimal(5,2)",
                oldPrecision: 5,
                oldScale: 2);

            migrationBuilder.UpdateData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedDate",
                value: new DateTime(2025, 6, 30, 5, 42, 45, 137, DateTimeKind.Utc).AddTicks(4608));

            migrationBuilder.UpdateData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedDate",
                value: new DateTime(2025, 6, 30, 5, 42, 45, 137, DateTimeKind.Utc).AddTicks(4614));

            migrationBuilder.UpdateData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedDate",
                value: new DateTime(2025, 6, 30, 5, 42, 45, 137, DateTimeKind.Utc).AddTicks(4616));

            migrationBuilder.UpdateData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedDate",
                value: new DateTime(2025, 6, 30, 5, 42, 45, 137, DateTimeKind.Utc).AddTicks(4617));

            migrationBuilder.UpdateData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedDate",
                value: new DateTime(2025, 6, 30, 5, 42, 45, 137, DateTimeKind.Utc).AddTicks(4619));
        }
    }
}
