using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BarbeariaApi.Models;
using BarbeariaApi.Data;
using Microsoft.AspNetCore.Authorization;

namespace BarbeariaApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AgendamentosController : ControllerBase
{
    private readonly BarbeariaContext _context;

    public AgendamentosController(BarbeariaContext context) { _context = context; }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Agendamento>>> GetAgendamentos(
        [FromQuery] string? status = null,
        [FromQuery] string? barbeiro = null,
        [FromQuery] DateTime? dataInicio = null,
        [FromQuery] DateTime? dataFim = null)
    {
        var query = _context.Agendamentos.AsQueryable();

        // Filtros opcionais
        if (!string.IsNullOrEmpty(status))
            query = query.Where(a => a.Status == status);

        if (!string.IsNullOrEmpty(barbeiro))
            query = query.Where(a => a.NomeBarbeiro.Contains(barbeiro));

        if (dataInicio.HasValue)
            query = query.Where(a => a.DataHora >= dataInicio.Value);

        if (dataFim.HasValue)
            query = query.Where(a => a.DataHora <= dataFim.Value);

        return await query.OrderBy(a => a.DataHora).ToListAsync();
    }

    [HttpGet("estatisticas")]
    [Authorize]
    public async Task<ActionResult<object>> GetEstatisticas()
    {
        var hoje = DateTime.Today;
        var inicioMes = new DateTime(hoje.Year, hoje.Month, 1);
        var fimMes = inicioMes.AddMonths(1).AddDays(-1);

        var stats = new
        {
            TotalAgendamentos = await _context.Agendamentos.CountAsync(),
            AgendamentosHoje = await _context.Agendamentos
                .CountAsync(a => a.DataHora.Date == hoje && a.Status == "Agendado"),
            AgendamentosMes = await _context.Agendamentos
                .CountAsync(a => a.DataHora >= inicioMes && a.DataHora <= fimMes),
            Concluidos = await _context.Agendamentos.CountAsync(a => a.Status == "Concluído"),
            Cancelados = await _context.Agendamentos.CountAsync(a => a.Status == "Cancelado"),
            PorBarbeiro = await _context.Agendamentos
                .GroupBy(a => a.NomeBarbeiro)
                .Select(g => new { Barbeiro = g.Key, Total = g.Count() })
                .ToListAsync()
        };

        return Ok(stats);
    }

    [HttpPost]
    public async Task<ActionResult<Agendamento>> PostAgendamento(Agendamento novoAgendamento)
    {
        // Validação: verificar se já existe agendamento no mesmo horário
        var conflito = await _context.Agendamentos
            .AnyAsync(a => a.NomeBarbeiro == novoAgendamento.NomeBarbeiro
                        && a.DataHora == novoAgendamento.DataHora
                        && a.Status == "Agendado");

        if (conflito)
        {
            return BadRequest(new { message = "Este horário já está ocupado para o barbeiro selecionado." });
        }

        novoAgendamento.Status = "Agendado";
        _context.Agendamentos.Add(novoAgendamento);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetAgendamentos), new { id = novoAgendamento.Id }, novoAgendamento);
    }

    // --- ENDPOINTS PROTEGIDOS PARA ADMIN ---

    [Authorize]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteAgendamento(int id)
    {
        var agendamento = await _context.Agendamentos.FindAsync(id);
        if (agendamento == null) return NotFound();
        _context.Agendamentos.Remove(agendamento);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [Authorize]
    [HttpPut("{id}/concluir")]
    public async Task<IActionResult> MarcarComoConcluido(int id)
    {
        var agendamento = await _context.Agendamentos.FindAsync(id);
        if (agendamento == null) return NotFound();
        agendamento.Status = "Concluído";
        _context.Entry(agendamento).State = EntityState.Modified;
        await _context.SaveChangesAsync();
        return Ok(agendamento);
    }

    [Authorize]
    [HttpPut("{id}/cancelar")]
    public async Task<IActionResult> CancelarAgendamento(int id)
    {
        var agendamento = await _context.Agendamentos.FindAsync(id);
        if (agendamento == null) return NotFound();
        agendamento.Status = "Cancelado";
        _context.Entry(agendamento).State = EntityState.Modified;
        await _context.SaveChangesAsync();
        return Ok(agendamento);
    }
}
