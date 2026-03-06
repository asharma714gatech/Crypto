FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["TMCryptoCore.csproj", "./"]
RUN dotnet restore "TMCryptoCore.csproj"

COPY . .
RUN dotnet build "TMCryptoCore.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "TMCryptoCore.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=publish /app/publish .

EXPOSE 5000 5001

ENTRYPOINT ["dotnet", "TMCryptoCore.dll"]
