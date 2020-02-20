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

#install rhino (with “-package -quiet” args)
RUN "`
    $Url = 'https://www.rhino3d.com/download/rhino-for-windows/7/wip/direct?email=studio@crh.io';`
    if ((Test-Path env:RH_RELEASE_DATE_ENV) -and (Test-Path env:RH_BUILD_ENV)) { $Url = 'http://files.mcneel.com/dujour/exe/'+ $env:RH_RELEASE_DATE_ENV+ '/rhino_en-us_' + $env:RH_BUILD_ENV +'.exe' };`
    $ProgressPreference = 'SilentlyContinue';`
    Invoke-WebRequest $Url -OutFile rhino_installer.exe`
    "

RUN Start-Process .\rhino_installer.exe -ArgumentList '-package', '-quiet' -NoNewWindow -Wait
RUN Remove-Item .\rhino_installer.exe

COPY --from=builder ["/src/bin/Release", "/app"]

#install ngrok for testing
RUN "`
    $Url = 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-windows-386.zip';`
    $ProgressPreference = 'SilentlyContinue';`
    Invoke-WebRequest $Url -OutFile ngrok.zip`
    "
RUN Expand-Archive -Path 'ngrok.zip'
COPY ./ngrok-config.yml \ngrok
WORKDIR \ngrok
EXPOSE 4040
#CMD [".\ngrok.exe start -config .\ngrok-config.yml checker"]
# RUN .\ngrok.exe start -config .\ngrok-config.yml checker

WORKDIR \app
EXPOSE 80
CMD ["compute.frontend.exe"]
