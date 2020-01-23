# escape=`

# NOTE: use 'process' isolation to build image (otherwise rhino fails to install)

ARG WIN_BUILD=1903

### builder image
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8 as builder

# copy everything, restore packages and build app
COPY src/ ./src/
RUN msbuild ./src/compute.sln /t:build /restore /p:Configuration=Release

### main image
FROM mcr.microsoft.com/windows:$WIN_BUILD
SHELL ["powershell", "-Command"]

ARG RH_BUILD
ENV RH_BUILD_ENV=${RH_BUILD}
ARG RH_RELEASE_DATE
ENV RH_RELEASE_DATE_ENV=${RH_RELEASE_DATE}

install rhino (with “-package -quiet” args)
RUN "`
    $Form = @{'email'='studio@crh.io';'current_page'='download_new'};`
    $result = Invoke-RestMethod -Uri https://www.rhino3d.com/download/rhino/wip -Method Post -Body $Form | Select-String -Pattern 'http.*dujour\/exe\/([0-9]*)\/rhino_en-us_(.*)\.exe';`
    if (-not (Test-Path env:RH_RELEASE_DATE_ENV)) { $env:RH_RELEASE_DATE_ENV = $result.matches.groups[1].Value };`
    if (-not (Test-Path env:RH_BUILD_ENV)) { $env:RH_BUILD_ENV = $result.matches.groups[2].Value };`
    $ProgressPreference = 'SilentlyContinue';`
    $Url = 'http://files.mcneel.com/dujour/exe/'+ $env:RH_RELEASE_DATE_ENV+ '/rhino_en-us_' + $env:RH_BUILD_ENV +'.exe';`
    Invoke-WebRequest $Url -OutFile rhino_installer.exe`
    "

RUN Start-Process .\rhino_installer.exe -ArgumentList '-package', '-quiet' -NoNewWindow -Wait
RUN Remove-Item .\rhino_installer.exe

COPY --from=builder ["/src/bin/Release", "/app"]

WORKDIR /app

EXPOSE 80

CMD ["compute.frontend.exe"]
