# escape=`

# base image should match the host operating system
# rhino only works with process isolation
FROM mcr.microsoft.com/windows:1903

# Install NuGet CLI
ENV NUGET_VERSION 5.3.1
RUN mkdir "%ProgramFiles%\NuGet" `
    && curl -fSLo "%ProgramFiles%\NuGet\nuget.exe" https://dist.nuget.org/win-x86-commandline/v%NUGET_VERSION%/nuget.exe

# Install VS components
RUN `
    # Install VS Test Agent
    curl -fSLo vs_TestAgent.exe https://download.visualstudio.microsoft.com/download/pr/c7d8bceb-64c4-426d-85a2-89bc21b21245/43d1b07a15fa7c77ed6f5e0011d1966c2d6e2610e6a293dfa25dde277abbba94/vs_TestAgent.exe `
    && start /w vs_TestAgent.exe --quiet --norestart --nocache --wait `
    && powershell -Command "if ($err = dir $Env:TEMP -Filter dd_setup_*_errors.log | where Length -gt 0 | Get-Content) { throw $err }" `
    && del vs_TestAgent.exe `
    `
    # Install VS Build Tools
    && curl -fSLo vs_BuildTools.exe https://download.visualstudio.microsoft.com/download/pr/c7d8bceb-64c4-426d-85a2-89bc21b21245/1f07eb88f128370a60ab6d592b1e0f3deb76036a168c7e3021d0fbaf4316a5a0/vs_BuildTools.exe `
    # Installer won't detect DOTNET_SKIP_FIRST_TIME_EXPERIENCE if ENV is used, must use setx /M
    && setx /M DOTNET_SKIP_FIRST_TIME_EXPERIENCE 1 `
    && start /w vs_BuildTools.exe ^ `
        --add Microsoft.VisualStudio.Workload.MSBuildTools ^ `
        --add Microsoft.VisualStudio.Workload.NetCoreBuildTools ^ `
        --add Microsoft.Net.Component.4.8.SDK ^ `
        --add Microsoft.Component.ClickOnce.MSBuild ^ `
        --add Microsoft.VisualStudio.Component.WebDeploy ^ `
        --quiet --norestart --nocache --wait `
    && powershell -Command "if ($err = dir $Env:TEMP -Filter dd_setup_*_errors.log | where Length -gt 0 | Get-Content) { throw $err }" `
    && del vs_BuildTools.exe `
    `
    # Cleanup
    && rmdir /S /Q "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer" `
    && powershell Remove-Item -Force -Recurse "%TEMP%\*" `
    && rmdir /S /Q "%ProgramData%\Package Cache"

# Install web targets
RUN curl -fSLo MSBuild.Microsoft.VisualStudio.Web.targets.zip https://dotnetbinaries.blob.core.windows.net/dockerassets/MSBuild.Microsoft.VisualStudio.Web.targets.2019.12.zip `
    && tar -zxf MSBuild.Microsoft.VisualStudio.Web.targets.zip -C "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Microsoft\VisualStudio\v16.0" `
    && del MSBuild.Microsoft.VisualStudio.Web.targets.zip

ENV DOTNET_USE_POLLING_FILE_WATCHER=true `
    ROSLYN_COMPILER_LOCATION="C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn"

# # ngen assemblies queued by VS installers - must be done in cmd shell to avoid access issues
# RUN `
#     # Workaround for issues with 64-bit ngen
#     \Windows\Microsoft.NET\Framework64\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\SecAnnotate.exe" `
#     && \Windows\Microsoft.NET\Framework64\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\WinMDExp.exe" `
#     `
#     && \Windows\Microsoft.NET\Framework64\v4.0.30319\ngen update `
#     `
#     # Workaround for issues with 32-bit ngen
#     && \Windows\Microsoft.NET\Framework\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\TestAgent\Common7\IDE\VSWebLauncher.exe" `
#     && \Windows\Microsoft.NET\Framework\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\csc.exe.config" `
#     && \Windows\Microsoft.NET\Framework\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\csc.rsp" `
#     && \Windows\Microsoft.NET\Framework\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\csi.exe.config" `
#     && \Windows\Microsoft.NET\Framework\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\csi.rsp" `
#     && \Windows\Microsoft.NET\Framework\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\Microsoft.CSharp.Core.targets" `
#     && \Windows\Microsoft.NET\Framework\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\Microsoft.Managed.Core.targets" `
#     && \Windows\Microsoft.NET\Framework\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\Microsoft.VisualBasic.Core.targets" `
#     && \Windows\Microsoft.NET\Framework\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\vbc.exe.config" `
#     && \Windows\Microsoft.NET\Framework\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\vbc.rsp" `
#     && \Windows\Microsoft.NET\Framework\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\VBCSCompiler.exe.config" `
#     && \Windows\Microsoft.NET\Framework\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\Microsoft.DiaSymReader.Native.amd64.dll" `
#     && \Windows\Microsoft.NET\Framework\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\Microsoft.DiaSymReader.Native.x86.dll" `
#     `
#     && \Windows\Microsoft.NET\Framework\v4.0.30319\ngen update

# Set PATH in one layer to keep image size down.
RUN powershell setx /M PATH $(${Env:PATH} `
    + \";${Env:ProgramFiles}\NuGet\" `
    + \";${Env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\TestAgent\Common7\IDE\CommonExtensions\Microsoft\TestWindow\" `
    + \";${Env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\" `
    + \";${Env:ProgramFiles(x86)}\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\" `
    + \";${Env:ProgramFiles(x86)}\Microsoft SDKs\ClickOnce\SignTool\")"

# Install Targeting Packs
RUN powershell " `
    $ErrorActionPreference = 'Stop'; `
    $ProgressPreference = 'SilentlyContinue'; `
    @('4.0', '4.5.2', '4.6.2', '4.7.2', '4.8') `
    | %{ `
        Invoke-WebRequest `
            -UseBasicParsing `
            -Uri https://dotnetbinaries.blob.core.windows.net/referenceassemblies/v${_}.zip `
            -OutFile referenceassemblies.zip; `
        Expand-Archive referenceassemblies.zip -DestinationPath \"${Env:ProgramFiles(x86)}\Reference Assemblies\Microsoft\Framework\.NETFramework\"; `
        Remove-Item -Force referenceassemblies.zip; `
    }"

# install rhino (with “-package -quiet” args)
# NOTE: edit this if you use a different version of rhino!
ADD http://files.mcneel.com/dujour/exe/20200107/rhino_en-us_7.0.20007.12535.exe rhino_installer.exe
RUN powershell -Command " `
    Start-Process .\rhino_installer.exe -ArgumentList '-package', '-quiet' -NoNewWindow -Wait; `
    Remove-Item .\rhino_installer.exe"

# compile compute
COPY src src
RUN powershell -Command "MSBuild.exe .\src\compute.sln /t:build /restore /p:Configuration=Release "
EXPOSE 80

CMD .\src\bin\Release\compute.frontend.exe

#buid with >docker build --isolation=process .  -t rhino-compute && docker run -it rhino-compute:latest powershell
