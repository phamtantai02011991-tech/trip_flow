# Multi-stage build for ASP.NET Core Web API (.NET 10)
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
WORKDIR /src

# Copy project file and restore
COPY ["TripFlow.Api.csproj", "./"]
RUN dotnet restore "TripFlow.Api.csproj"

# Copy source and publish
COPY . .
RUN dotnet publish "TripFlow.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS final
WORKDIR /app

# Install curl for docker healthcheck
RUN apk add --no-cache curl

# Copy published files
COPY --from=build /app/publish .

# Environment
ENV ASPNETCORE_URLS=http://+:8000
ENV ASPNETCORE_ENVIRONMENT=Production
EXPOSE 8000

ENTRYPOINT ["dotnet", "TripFlow.Api.dll"]
