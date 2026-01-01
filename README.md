<div align="center">

# PSBITE

**PSBITE** stand for "**P**ower**S**hell **B**uffer **I**nsert **T**ext **E**ditor".
</div>

It's a VIM-like text editor that supports both local and remote file editing.
It provides a familiar VIM interface with NORMAL and INSERT modes, character operations, and real-time remote synchronization.


<p align="center"> <img src="./media/Logo/PSBITE%20-%20Small.png" alt="Logo" /> </p>

<div align="center">

[![starline](https://starlines.qoo.monster/assets/arnaudcharles/psbite)](https://github.com/qoomon/starline)

![PowerShell](https://img.shields.io/badge/PS%20Module-207bcd)
![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-5391FE?style=flat-square&logo=powershell&logoColor=white&labelColor=2C3E50)
![GitHub Stars](https://img.shields.io/github/stars/arnaudcharles/psbite?style=flat-square&logo=github&color=FFD700&labelColor=2C3E50)
![GitHub License](https://img.shields.io/github/license/arnaudcharles/psbite)
![GitHub Release](https://img.shields.io/github/v/release/arnaudcharles/psbite)

</div>
<br>
<br>

💡 Included : Another function, **Edit-RemoteFile** is providing another way to remotly **open/editing** file with **VSCode** (or notepad) using **WinRM**.

## 👀 What it look like

**>_ Windows Terminal**
<p align="center"> <img src="./media/Start-PSBite/Main0.png" alt="WT Edit 1" /> </p>

<p align="center"> <img src="./media/Start-PSBite/Main1.png" alt="WT Edit 1" /> </p>

## 💪 Advantages

<table align="center">
<tr>
<td align="center" style="color: #8d2640ff">🔗<br><b>No dependency</b></td>
<td align="center" style="color: #6a741cff">🔒<br><b>Secure</b></td>
<td align="center" style="color: #3d9393ff">⌨️<br><b>Keyboard only</b></td>
<td align="center" style="color: #207bcd">📝<br><b>Vim like</b></td>
<td align="center" style="color: #20cda8ff">🫧<br><b>Lightweight</b></td>
</tr>
</table>

## 📄 Prerequisites

- Require PowerShell 7

## 📦 Installation

To install the module from the [PowerShell Gallery](https://www.powershellgallery.com/packages/PSBITE/), you can use the following command:

```powershell
Install-PSResource -Name PSBITE
Import-Module -Name PSBITE
```

💡 Feel free to create an alias in your profile `vim`, `bite`, `psb`, `teub` !

## 🔩 Example of Usage

Here is a list of example that are typical use cases for the module.

<p align="left" style="color: #356ebeff; font-size: 24px;">Using PSBITE 〲</p>

Edit a remote file with real-time synchronization

```powershell
Start-PSBite -FilePath "C:\scripts\remote.ps1" -ComputerName "server01"
```

**Opening a file in Normal Mode**
![Opening a file in Normal Mode](./media/Start-PSBite/Start-PSBite_1.png)

**Editing the same file**
![Editing the same file](./media/Start-PSBite/Start-PSBite_2.png)

<br>

-------------------------

<br>

<p align="left" style="color: #356ebeff; font-size: 24px;">Using Edit-RemoteFile 〲</p>

Edit with bidirectional synchronization (remote changes are pulled to local)

```powershell
Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1" -Dual
```
**Simple example of Edit-RemoteFile**
![Example of Edit-RemoteFile with simple sync](./media/Edit-RemoteFile/Edit-RemoteFile_1.png)

**Showing the ending process**
![Show how the edit is ended](./media/Edit-RemoteFile/Edit-RemoteFile_2.png)

**Showing the Dual and DelTemp, used on a logs**
![Show the Dual and DelTemp flags](./media/Edit-RemoteFile/Edit-RemoteFile_3.png)


### Find more examples

To find more examples of how to use the module, please refer to the [examples](examples) folder.

Alternatively, you can use the Get-Command -Module 'PSBITE' to find more commands that are available in the module.
To find examples of each of the commands you can use Get-Help -Examples 'CommandName'.


## 📌 How to use it

### Edit-RemoteFile
```powershell
.PARAMETER ComputerName
# Remote server name or FQDN

.PARAMETER RemotePath
# Full path to the file on the remote server

.PARAMETER LocalTempDir
# Local temporary directory for file synchronization (default: $env:TEMP\RemoteEdit)

.PARAMETER UseSSL
# Use SSL for WinRM connection (default: true)

.PARAMETER DelTemp
# Delete temporary file when finished (default: false - file is preserved)

.PARAMETER Dual
# Enable bidirectional synchronization - monitors both local and remote file changes

.PARAMETER Silent
# Minimal output - show only essential connection and monitoring messages

.PARAMETER Verbose
# Enable verbose output for debugging and detailed information. SO AJ :-)

.EXAMPLE
Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1"
# Edit a remote PowerShell script with SSL and unidirectional sync

.EXAMPLE
Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1" -Dual
# Edit with bidirectional synchronization (remote changes are pulled to local)

.EXAMPLE
Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1" -Silent
# Edit with minimal output showing only essential messages

.EXAMPLE
Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1" -DelTemp
# Edit and delete temporary file when finished

.EXAMPLE
Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1" -Verbose
# Edit with verbose output showing file paths
```

### Start-PSBite
```powershell
.PARAMETER FilePath
# Path to the file to edit (local or remote). Can be relative or absolute for local but must be absolute when using the remote.

.PARAMETER ComputerName
# Remote computer name for remote editing (optional)

.PARAMETER UseSSL
# Use SSL for remote connection (default: true)

.EXAMPLE
Start-PSBite -FilePath "C:\test.txt"
# Edit a local file

.EXAMPLE
Start-PSBite -FilePath "C:\scripts\remote.ps1" -ComputerName "server01"
# Edit a remote file with real-time synchronization

.NOTES
# Controls:
- i       : Enter INSERT mode
- Esc     : Enter NORMAL mode
- y       : Yank (copy) line
- dd      : Delete line
- p       : Paste line
- :w      : Save file
- :q      : Quit
- :q!     : Quit without saving
- :wq     : Save and quit
```

## ⚔️ How Edit-RemoteFile differ from Start-PSBite ?

They don't use the same method to work.
PSBite is a VI like that capture the key touched to do action where Edit-RemoteFile monitor the file to take action.

| Start-PSBite | Edit-RemoteFile |
|---|---|
| 🎹 Built-in editor | 📁 External monitoring |
| ⌨️ Responds to keystrokes | 👁️ Monitors the file |
| 📝 Direct editing | 🔄 Change detection |
| 💾 AutoSave timer | 📊 Polling timestamp |
| 🖥️ Terminal interface | 🔗 VSCode/Notepad |


## 📰 How it started

Since I was using core server, as soon as you need to manipulate file, logs or create file without GUI it was honestly a nightmare for me. I was not able to find something like nano built-in or even depending on VSCode. Because I'm working in a high secure area, we cannot afford to install cosmetic or non approved software like Vim on each servers. This is where the creation of this module started, because custom and selfmade PowerShell module are already running why not creating mine that can benefit my daily work and help the community ?

It was like a challenge after attemping [PSConf](https://psconf.eu/), I wanted to make something that was able to make me proud and ready to myself go on stage next time.

Then Edit-RemoteFile came alive in parallel for the same reasons, mainly for internal usage but finally integrated to PSBite because it's working not the same way and can also benefit to other users.


## 🔗 Functions dependencies

See [Function Dependencies](DEPENDENCIES.md) to understand link between each functions.


## 🔧 Contributing

Coder or not, you can contribute to the project! We welcome all contributions.

### 🧑‍💻 For Users

If you don't code, you still sit on valuable information that can make this project even better. If you experience that the
product does unexpected things, throw errors or is missing functionality, you can help by submitting bugs and feature requests.
Please see the issues tab on this project and submit a new issue that matches your needs.

### 🧑‍🔧 For Developers

If you do code, we'd love to have your contributions. Please read the [Contribution guidelines](CONTRIBUTING.md) for more information.
You can either help by picking up an existing issue or submit a new one if you have an idea for a new feature or improvement.

## 📣 Ref

Thanks to [Marius](https://github.com/MariusStorhaug) for his job on [PsModule Framework](https://psmodule.io/ ) used to built the skeleton of PSBITE.

Thanks to my colleagues who challenged me, helped me publish it and using it daily.



