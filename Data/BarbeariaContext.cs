using Microsoft.EntityFrameworkCore;
using BarbeariaApi.Models;

namespace BarbeariaApi.Data;

public class BarbeariaContext : DbContext
{
    public BarbeariaContext(DbContextOptions<BarbeariaContext> options)
        : base(options)
    {
    }

    public DbSet<Agendamento> Agendamentos { get; set; } = null!;
    // --- ADICIONE ESTA LINHA ---
    public DbSet<Barbeiro> Barbeiros { get; set; } = null!;
}