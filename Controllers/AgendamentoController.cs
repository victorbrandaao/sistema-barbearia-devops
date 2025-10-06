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
    public async Task<ActionResult<IEnumerable<Agendamento>>> GetAgendamentos()
    {
        // Agora ordena por data para o admin ver em ordem cronológica
        return await _context.Agendamentos.OrderBy(a => a.DataHora).ToListAsync();
    }

    [HttpPost]
    public async Task<ActionResult<Agendamento>> PostAgendamento(Agendamento novoAgendamento)
    {
        novoAgendamento.Status = "Agendado"; // Garante o status inicial
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
