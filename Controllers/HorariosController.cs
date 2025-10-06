using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BarbeariaApi.Data;

namespace BarbeariaApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HorariosController : ControllerBase
{
    private readonly BarbeariaContext _context;

    public HorariosController(BarbeariaContext context)
    {
        _context = context;
    }

    [HttpGet("disponiveis")]
    public async Task<ActionResult<IEnumerable<string>>> GetHorariosDisponiveis([FromQuery] DateTime data)
    {
        // Define o horário de funcionamento da barbearia
        var horarioAbertura = new TimeSpan(9, 0, 0); // 09:00
        var horarioFechamento = new TimeSpan(19, 0, 0); // 19:00
        var duracaoSlot = new TimeSpan(1, 0, 0); // Slots de 1 hora

        var todosOsHorarios = new List<string>();
        var horarioAtual = horarioAbertura;

        while (horarioAtual < horarioFechamento)
        {
            todosOsHorarios.Add(horarioAtual.ToString(@"hh\:mm"));
            horarioAtual = horarioAtual.Add(duracaoSlot);
        }

        // Busca os horários já agendados para a data especificada
        var agendamentosDoDia = await _context.Agendamentos
            .Where(a => a.DataHora.Date == data.Date && a.Status == "Agendado")
            .Select(a => a.DataHora.TimeOfDay.ToString(@"hh\:mm"))
            .ToListAsync();

        // Filtra para retornar apenas os horários que não estão na lista de agendados
        var horariosDisponiveis = todosOsHorarios.Except(agendamentosDoDia);

        return Ok(horariosDisponiveis);
    }
}
