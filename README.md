# Rhino Compute Server

[![Build status](https://ci.appveyor.com/api/projects/status/unmnwi57we5nvnfi/branch/master?svg=true)](https://ci.appveyor.com/project/mcneel/compute-rhino3d/branch/master)
[![Discourse users](https://img.shields.io/discourse/https/discourse.mcneel.com/users.svg)](https://discourse.mcneel.com/c/serengeti/compute-rhino3d)
[![YouTrack issues](https://img.shields.io/badge/youtrack-COMPUTE-blue.svg)](https://mcneel.myjetbrains.com/youtrack/issues?q=project:%20Compute)

![https://www.rhino3d.com/compute](https://www.rhino3d.com/en/7.420921340460724505/images/rhino-compute-new.svg)

## REST API exposing Rhino's geometry core.

This project is composed of two applications:
- `compute.geometry` provides the geometry REST API
- `/export/{extension}` perfoms fileIO operation on supported file formats
- `compute.frontend` provides authentication, request stashing (saving POST data for diagnostics), logging, and configuration of request and response headers. `compute.frontend` creates the `compute.geometry` process, monitors its health, and restarts `compute.geometry` as necessary.

Compute is built on top of Rhino 7 for Windows and can run anywhere Rhino 7 for Windows can run. The two typical scenarios are running as a web server on a remote Window Server operating system and running locally on a user's computer for debugging or providing local services to applications.

Start with the [installation guide](docs/installation.md) to setup your own Compute server, or [compile Compute](docs/installation.md#building-from-source-and-debugging) and start developing your own features.

For more information, see https://www.rhino3d.com/compute

# Docker Setup

# Preparation
Need a Windows Pro / Server machine with Docker for Windows Desktop installed.
Acquire the license files:  
https://discourse.mcneel.com/t/docker-support/89322

Rhino Download (always get the latest version of Rhino WIP):  
https://files.mcneel.com/dujour/exe/20190917/rhino_en-us_7.0.19260.11525.exe

# Building the Image
`docker build --isolation=process . -t rhino-compute`

Following Build arguments are available:

| Build Argument  | Default |
| ------------- | ------------- |
| WIN_BUILD  | 1903  |
| RH_RELEASE_DATE  | Latest  |
| RH_BUILD  | Latest  |

# Running Image
Mount the license files and run the image:

`docker run --mount source=license,target="C:/ProgramData/McNeel/Rhinoceros/6.0/License Manager/Licenses" --mount source=cloudzoo,target="C:/Users/ContainerAdministrator/AppData/Roaming/McNeel/Rhinoceros/6.0/License Manager/Licenses" --mount source=settings,target="C:/Users/ContainerAdministrator/AppData/Roaming/McNeel/Rhinoceros/7.0/settings" -p 8000:80 rhino-compute:latest
`

# Debugging Image
`docker run -it rhino-compute:latest powershell`
