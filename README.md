# Dev Containers, Codespaces and more for Azure PowerShell Function Apps

Recently, I listened to the [PowerShell Podcast](https://powershellpodcast.podbean.com/) episode with [Barbara Forbes](https://www.4bes.nl/) and she mentioned [devcontainers](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers) and her blog post: [Use GitHub Codespaces for Azure PowerShell Function apps](https://4bes.nl/2022/11/13/use-github-codespaces-for-azure-powershell-function-apps/)

I've heard so much dev containers, like Brett Miller talks about them all the time, too.

![image](https://user-images.githubusercontent.com/8278033/212470035-d709463c-d9e2-4556-a74e-386b1b1a0a2f.png)

In addition to Brett, other PowerShell friends, including [Jess Pomfret](https://github.com/dataplat/dbatools-lab) and [Rob Sewell](https://blog.robsewell.com/blog/community/dev%20containers/github-pages-in-devcontainers-and-codespaces/) and [Shawn Melton](https://github.com/dataplat/dbatools/tree/development/.devcontainer) are suggesting devcontainers, so the moment I was back at my computer, I read Barbara's blog post, cloned [the repo](https://github.com/Ba4bes/AzureFunctions-CodeSpaces) and messed around. 

This repository is the result.

# About this repo

There are a few key differences between my repo and Barbara's; primarily I updated the devcontainer version to PowerShell v7 and the Azure Functions to v4. I also added a sample Azure Function and removed a few default OS-related errors/warnings.

Here's a gem: according to [DevContainers for Azure and .NET](https://dev.to/azure/devcontainers-for-azure-and-net-5942), here's the build order for devcontaineres.

1. Build the Docker container. If you add the shell script through the RUN command in Dockerfile, the shell script is run this time.
1. Run features declared in the features section of devcontainer.json while building the Docker container.
1. Run commands declared in the postCreateCommand attribute of devcontainer.json.
1. Apply dotfiles after postCreateCommand, if you have it.
1. Apply both extensions and settings of devcontainer.json at the startup of the DevContainer.

So here's directory structure for what I think I'll be using a template for my Azure Function repos.

```
.
├── .devcontainer
│   ├── Dockerfile
│   └── devcontainer.json
├── .github
│   └── workflows
│       └── function.yml
├── .gitignore
├── .vscode
│   ├── extensions.json
│   ├── launch.json
│   ├── settings.json
│   └── tasks.json
├── README.md
└── functions
    ├── .gitignore
    ├── Modules
    │   └── azHelper
            ├── azHelper.psd1
            └── azHelper.psm1
    ├── host.json
    ├── local.settings.json
    ├── profile.ps1
    ├── requirements.psd1
    ├── templates
    └── greetingGet
        ├── function.json
        └── run.ps1
```

### .devcontainer

This directory contains a `Dockerfile` that builds the container. I could also add in a `docker-compose.yml` file which I probably will later with more advanced setups when I want to include a "network" of containers, like for [SQL Server projects](https://github.com/dataplat/dbatools/tree/development/.devcontainer).

I added more VS Code customizations into the `devcontainer.json` to address warnings that pop up about Windows PowerShell not existing, so I forced the dev container to look for PowerShell on Linux.

![image](https://user-images.githubusercontent.com/8278033/212470200-1ee592c7-1225-44d5-8ed2-f87fb0cae3f0.png)


I also removed the following line:

```
"ghcr.io/devcontainers/features/azure-cli:1": {}
```

I saw [GitHub's Dev Container Features](https://containers.dev/features) used by others, including Jess who uses it to install both the azurecli and git. I think features are literally compiled to ensure they work well (maybe?) because it took a _long_ time for the features to install on my container. 

> Just figured it out! I was installing git and the feature literally says "(from source)" so it was indeed compiling git.

Ultimately, the updated Azure Functions container already has the Azure CLI installed and I just used `apt get` to install whatever else I wanted in the `Dockerfile`. This seemed much faster.

I'll probably revist this decision in the future, though, because the list of features seems super useful.

### .github

Azure Functions can be published automatically from GitHub Actions! I haven't done it yet but this folder contains is the workflow template that was provided by Microsoft.

### .gitignore

That Azurite Azure Storage Emulator creates a ton of files named like `__azurite_db_blob_extent__.json` so I ignore them all in git and VS Code.

### .vscode

###### launch.json

The VS Code files are pretty standard but I did add a Node entry to `launch.json` because it worked well for me in the past (and it ran PowerShell Azure Functions) and I like options. So far, though, the PowerShell entry is my default.

###### settings.json

This has an important setting: the root location of my Azure Functions, which I simply named `functions`.

```
"azureFunctions.deploySubpath": "functions",
```

I also reiterated the location of PowerShell on Linux. Without this one (or maybe the other entry in `devcontainer.json`), I get the following error when attempting to debug:

![image](https://user-images.githubusercontent.com/8278033/212469994-cdb43eec-ed85-41e3-ba98-fa3475cd10ef.png)

Oh, and I ignored all those files that Azurite generates.

### functions

Took me a while but this is what I decided to name the folder that contains the actual functions. There doesn't seem to be a standard in Azure Function repos and I like this one.

###### Modules

This folder is important in PowerShell projects! The path is essenetially added to the system's [$env:PSModulePath](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell?tabs=portal).

Rob likes to place all module dependencies here, saying..

> the reason is to speed up function load time - because if we are on pay per minute we are paying to install the module every time so I was going to do a build of the repo every night and inject the latest dbatools release. Ultimately, putting the modules inside the container saves money and pins the version at the cost of requiring effort to maintain and update. Using requirements risks upstream dependencies breaking your shit but is much easier and simpler to add and remove new ones.

He's got a point there, especially considering how often the PowerShell Gallery fails :/ He went on to say

> It depends on each projects specifical requirements. But i think using requirements up front means that people don't need to know or worry about dealing with containers. So it's easier and when you have problems you need to come back and revisit

Barbara prefers `requirements.psd1`, saying..

> I would use requirements.psd1 unless there is a good reason not to. Good reason being that the modules are not in the Gallery, for example. Getting them from the Gallery means you have less management and always have the latest (major) version. Another reason can be very large modules. If you load the complete Az module, it takes more than 5 minutes and that ruins your start-time. So with Az you can use submodules, which will resolve that issue.

I'm still undecided (considering the Gallery's instability) but I think I'll use `requirements.psd1` for modules in the PowerShell Gallery and the Modules folder for internal modules or modified public modules.

###### templates

This is where I'll store my ARM templates or bicep or whatever, probably.

###### greetingGet

This is my actual test function! The folders will be named like this:

* vmGet
* vmNew
* vmStop
* storageCreate
* storageDelete

While the routes will look like this

* /vm/get
* /vm/new
* /vm/stop
* /storage/create
* /storage/delete

###### host.json

This has a bunch of non-default values that I found in a repo and I imagine it'll come in handy. One day, I'll find out why they used these values haha.

###### profile.ps1

I love that they enable profile loading! I'll likely use it to explicitly load slow-loading modules and set some things like [$PSDefaultParameterValues](https://dbatools.io/defaults/).


###### requirements.psd1

I don't need allllll of `Az` so I'm just loading some that I'll imagine I'll need as a SQL Server-centric developer.

Hope this was helpful for you if you're new to all of this!

# Using this repository as a Codespace

VS Code can run in a browser! It's wild. For me, I had to see it to understand so let's jump in with some screenshots.

First, click the green Code button then `Create codespace on main`.

![image](https://user-images.githubusercontent.com/8278033/212486955-268fd29c-236b-4a4c-924d-c68bb133c484.png)

Then it starts building a container!

![image](https://user-images.githubusercontent.com/8278033/212487043-f60aa4b7-a7a8-4a84-9c3f-c764d9b50f40.png)

And now VS Code appears, whaaaat! Check out my browser tabs at the top.

![image](https://user-images.githubusercontent.com/8278033/212488163-f4da19f4-389d-4f9b-a9ff-cb21cd54749b.png)

Then if you want to see a list, you can go to your [Codespaces page](https://github.com/codespaces).

![image](https://user-images.githubusercontent.com/8278033/212488446-cde2d273-8ab2-41c7-b67a-c63673d50255.png)

Here, you can even increase the size of your codespace. I haven't yet because I don't know what impact that has on the monthly free hours.

Alright, so next, let's get the Azure Functions App running by hitting debug.

![image](https://user-images.githubusercontent.com/8278033/212489005-724d16fe-3050-4c2d-9ddc-184125ac7b9e.png)

Wait until a prompt that pops up saying that your application is running on port 7071 (when this screenshot was created, the folder was named vmGet and not greetingGet). 

I'm including the whole VS Code screenshot because when I started doing functions, I wanted the tutorial to show what I'm supposed to be seeing.

![image](https://user-images.githubusercontent.com/8278033/212488987-9ebbb854-c467-46ba-a8f3-ea0bfad04bdf.png)

Go ahead and `Open in Browser` to be amazed!

![image](https://user-images.githubusercontent.com/8278033/212489332-244fb4b5-5b45-4601-bcdd-415f1a556ebe.png)

Next up, we'll execute the function. Click the Azure Extension, expand the workspace tab at the bottom, then right click on `greetingGet`. Then click `Execute Function Now...`

![image](https://user-images.githubusercontent.com/8278033/212529359-d2e6aa15-c400-431b-b29b-c5b4977e3f17.png)

A prompt will appear in the settings bar at the top and you can change the default name of `Azure` to anything you like.

![image](https://user-images.githubusercontent.com/8278033/212529448-71259c77-53cc-4cff-95de-ac499a78d1f4.png)

I changed it to `blog reader`. And here it is, successfully running!

![image](https://user-images.githubusercontent.com/8278033/212529489-d8bc4b4a-6bc7-4d73-82c6-1347bc2893b7.png)

:mindblown:

# Using a devcontainer

To use the [devcontainer](https://code.visualstudio.com/docs/devcontainers/containers) which contains everything you need, clone the repo however you do then open it in VS Code.

Ensure that the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) VS Code extension is installed. I imagine Docker alao has to be installed and running.

Once the extension is installed, a remote icon should appear in the lower-left hand corner.

![image](https://user-images.githubusercontent.com/8278033/212530684-a5a8dfe9-f6a4-47c4-a5d0-e5d4e519fa3d.png)

Click on it, then a drop-down will appear at the top. Select `Reopen in Container` in the `Dev Containers` group.

![image](https://user-images.githubusercontent.com/8278033/212531119-3f143df4-fc5e-4e89-b456-17de08ae052f.png)

Code will restart as a devcontainer!

![image](https://user-images.githubusercontent.com/8278033/212531488-6f38e00f-aa68-4d49-878d-ae1e0ca5a8ff.png)

Woo! Now you're set and you can follow all the last few steps in the [Codespaces](#using-this-repository-as-a-codespace) section, starting after `Alright, so next, let's get the Azure Functions App running by hitting debug.` because it's all the same :O
