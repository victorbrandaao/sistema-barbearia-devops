namespace BarbeariaApi.Models;

public class Agendamento
{
    public int Id { get; set; }
    public string NomeBarbeiro { get; set; } = string.Empty;
    public string NomeCliente { get; set; } = string.Empty;
    public DateTime DataHora { get; set; }
    public string Status { get; set; } = "Agendado"; // Valor padrão
}