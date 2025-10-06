using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BarbeariaApi.Migrations
{
    /// <inheritdoc />
    public partial class AddStatusToAgendamento : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Concluido",
                table: "Agendamentos");

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "Agendamentos",
                type: "text",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Status",
                table: "Agendamentos");

            migrationBuilder.AddColumn<bool>(
                name: "Concluido",
                table: "Agendamentos",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }
    }
}
