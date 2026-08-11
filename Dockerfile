FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /app

# Copy solution and project files explicitly
COPY SentinelApi.sln ./
COPY src/SentinelApi.Core/*.csproj ./src/SentinelApi.Core/
COPY src/SentinelApi.Infrastructure/*.csproj ./src/SentinelApi.Infrastructure/
COPY src/SentinelApi.Api/*.csproj ./src/SentinelApi.Api/
COPY tests/SentinelApi.Tests/*.csproj ./tests/SentinelApi.Tests/

# Restore dependencies for the solution
RUN dotnet restore SentinelApi.sln

# Copy all source files and publish
COPY . ./
RUN dotnet publish src/SentinelApi.Api/SentinelApi.Api.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

ENV DOTNET_USE_POLLING_FILE_WATCHER=true
ENV ASPNETCORE_URLS=http://+:8080
ENV PORT=8080

EXPOSE 8080
ENTRYPOINT ["dotnet", "SentinelApi.Api.dll"]
