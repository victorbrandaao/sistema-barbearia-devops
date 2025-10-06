using Microsoft.EntityFrameworkCore;
using BarbeariaApi.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// --- CONFIGURAÇÃO DE AUTENTICAÇÃO JWT ---
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = false, // Em prod, pode validar quem gerou o token
        ValidateAudience = false, // Em prod, pode validar para quem o token foi gerado
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
    };
});
// --- FIM DA CONFIGURAÇÃO DE AUTENTICAÇÃO ---

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<BarbeariaContext>(options =>
    options.UseNpgsql(connectionString));

// Habilitar CORS para permitir que o frontend acesse a API
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        policy =>
        {
            policy.AllowAnyOrigin()
                  .AllowAnyMethod()
                  .AllowAnyHeader();
        });
});


builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<BarbeariaContext>();
    db.Database.Migrate();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Adicionar middlewares de Roteamento, CORS, Autenticação e Autorização (A ORDEM É IMPORTANTE)
app.UseRouting();

app.UseCors("AllowAll"); // Habilita o CORS

app.UseAuthentication(); // 1. Verifica se o usuário está autenticado
app.UseAuthorization();  // 2. Verifica se o usuário autenticado tem permissão

app.MapControllers();

app.Run();