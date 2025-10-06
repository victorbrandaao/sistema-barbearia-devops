# --- Estágio 1: Build da Aplicação ---
# Usamos a imagem oficial do .NET SDK (Software Development Kit) que contém todas as ferramentas para compilar o projeto.
# 'AS build' dá um nome a este estágio, que usaremos depois.
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build

# Define o diretório de trabalho dentro do contêiner.
WORKDIR /source

# Copia os arquivos do projeto (.csproj) para o contêiner.
# Copiamos primeiro para aproveitar o cache do Docker. Se os projetos não mudarem, o passo de restore não precisa rodar de novo.
COPY *.csproj .

# Restaura as dependências do projeto (pacotes NuGet).
RUN dotnet restore

# Copia todo o resto do código fonte para o contêiner.
COPY . .

# Compila e publica a aplicação em modo de Release, otimizado para produção.
# O resultado será salvo no diretório /app/publish.
RUN dotnet publish -c Release -o /app/publish

# --- Estágio 2: Imagem Final ---
# Agora, usamos uma imagem muito menor, que contém apenas o necessário para RODAR a aplicação (ASP.NET Runtime).
# Isso torna nossa imagem final mais leve e segura.
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final

# Define o diretório de trabalho na imagem final.
WORKDIR /app

# Copia apenas os arquivos publicados do estágio 'build' para a imagem final.
COPY --from=build /app/publish .

# Define o comando que será executado quando o contêiner iniciar.
# Ele vai rodar a DLL da nossa API.
ENTRYPOINT ["dotnet", "BarbeariaApi.dll"]