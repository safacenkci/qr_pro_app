using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QrPro.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class DropClientIp : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "client_ip",
                table: "purchases");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "client_ip",
                table: "purchases",
                type: "text",
                nullable: true);
        }
    }
}
