FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /app

COPY *.sln* ./
COPY src/SentinelApi.Core/*.csproj ./src/SentinelApi.Core/
COPY src/SentinelApi.Infrastructure/*.csproj ./src/SentinelApi.Infrastructure/
COPY src/SentinelApi.Api/*.csproj ./src/SentinelApi.Api/
COPY tests/SentinelApi.Tests/*.csproj ./tests/SentinelApi.Tests/

RUN dotnet restore

COPY . ./
RUN dotnet publish src/SentinelApi.Api/SentinelApi.Api.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

EXPOSE 8080
ENTRYPOINT [\dotnet\, \SentinelApi.Api.dll\]
