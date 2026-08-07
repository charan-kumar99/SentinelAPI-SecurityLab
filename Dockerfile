# Multi-stage build for ASP.NET Core 10 API Security Lab
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /app

# Copy solution and project files
COPY *.sln* ./
COPY src/ApiSecurityLab.Core/*.csproj ./src/ApiSecurityLab.Core/
COPY src/ApiSecurityLab.Infrastructure/*.csproj ./src/ApiSecurityLab.Infrastructure/
COPY src/ApiSecurityLab.Api/*.csproj ./src/ApiSecurityLab.Api/
COPY tests/ApiSecurityLab.Tests/*.csproj ./tests/ApiSecurityLab.Tests/

RUN dotnet restore

# Copy full source and build release
COPY . ./
RUN dotnet publish src/ApiSecurityLab.Api/ApiSecurityLab.Api.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:5000
EXPOSE 5000

ENTRYPOINT ["dotnet", "ApiSecurityLab.Api.dll"]
