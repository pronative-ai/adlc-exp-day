FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY LeadApi/LeadApi.csproj LeadApi/
RUN dotnet restore LeadApi/LeadApi.csproj

COPY LeadApi/ LeadApi/
RUN dotnet publish LeadApi/LeadApi.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

EXPOSE 3000
ENTRYPOINT ["dotnet", "LeadApi.dll"]
