using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BarbeariaApi.Models;
using BarbeariaApi.Data;
using Microsoft.AspNetCore.Authorization;

namespace BarbeariaApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class BarbeirosController : ControllerBase
{
    private readonly BarbeariaContext _context;

    public BarbeirosController(BarbeariaContext context)
    {
        _context = context;
    }

    // GET: api/barbeiros (Público, para clientes verem a lista)
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Barbeiro>>> GetBarbeiros()
    {
        return await _context.Barbeiros.OrderBy(b => b.Nome).ToListAsync();
    }

    // --- ENDPOINTS PROTEGIDOS PARA ADMIN ---

    [Authorize]
    [HttpPost]
    public async Task<ActionResult<Barbeiro>> PostBarbeiro(Barbeiro barbeiro)
    {
        _context.Barbeiros.Add(barbeiro);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetBarbeiros), new { id = barbeiro.Id }, barbeiro);
    }

    [Authorize]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteBarbeiro(int id)
    {
        var barbeiro = await _context.Barbeiros.FindAsync(id);
        if (barbeiro == null)
        {
            return NotFound();
        }
        _context.Barbeiros.Remove(barbeiro);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}