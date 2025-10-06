using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using BarbeariaApi.Models; // Você precisará criar este modelo

namespace BarbeariaApi.Controllers;

public class LoginModel
{
    public string Username { get; set; }
    public string Password { get; set; }
}

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IConfiguration _config;

    public AuthController(IConfiguration config)
    {
        _config = config;
    }

    [HttpPost("login")]
    public IActionResult Login([FromBody] LoginModel login)
    {
        // Valida as credenciais contra o que está no appsettings (ou variáveis de ambiente)
        if (login.Username == _config["Admin:User"] && login.Password == _config["Admin:Password"])
        {
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, login.Username),
                new Claim("role", "admin") // Adiciona uma "claim" de role
            };

            var token = new JwtSecurityToken(
                issuer: "*",
                audience: "*",
                claims: claims,
                expires: DateTime.Now.AddHours(8), // Token expira em 8 horas
                signingCredentials: credentials);

            return Ok(new { token = new JwtSecurityTokenHandler().WriteToken(token) });
        }

        return Unauthorized();
    }
}