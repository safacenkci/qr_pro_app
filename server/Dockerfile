# Derleme aşaması
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY QrPro.Api/QrPro.Api.csproj QrPro.Api/
RUN dotnet restore QrPro.Api/QrPro.Api.csproj
COPY QrPro.Api/ QrPro.Api/
RUN dotnet publish QrPro.Api/QrPro.Api.csproj -c Release -o /app --no-restore -p:UseAppHost=false

# Çalışma aşaması
FROM mcr.microsoft.com/dotnet/aspnet:10.0
# Ayrıcalıksız kullanıcı (uid 10001). /secrets bağlaması bu kullanıcıya okunur olmalı (README).
RUN groupadd --system --gid 10001 qrpro \
    && useradd --system --uid 10001 --gid 10001 --no-create-home --shell /usr/sbin/nologin qrpro
WORKDIR /app
COPY --from=build /app .

# Paylaşımlı sunucu: iş istasyonu GC'si daha az bellek tutar.
ENV ASPNETCORE_HTTP_PORTS=8080 \
    DOTNET_gcServer=0 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1

USER 10001:10001
EXPOSE 8080
# Konteyner yalnızca 127.0.0.1'e yayınlanır; gelen her bağlantı nginx'tendir, X-Forwarded-For güvenilir.
ENTRYPOINT ["dotnet", "QrPro.Api.dll"]
