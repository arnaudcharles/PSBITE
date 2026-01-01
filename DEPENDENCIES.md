# PSbite Module Dependencies

This diagram shows dependencies between public (exported) and private (internal) functions in the module.

- **Green rounded rectangles**: Public functions (exported)
- **Blue rectangles**: Private functions (internal)
- **Solid arrows**: Public → Private dependencies
- **Dashed arrows**: Private → Private dependencies

```mermaid
graph TD
    N0([Edit-RemoteFile])
    N1([Start-PSBite])
    N2[Invoke-PSBiteKeyNavigation]
    N3[Invoke-PSBiteKeyPress]
    N4[Invoke-RemotePSBiteKeyPress]
    N13[Read-FileWatcher]
    N12[Read-PSBiteCommand]
    N5[Read-RemoteFile]
    N6[Save-PSBiteFile]
    N10[Start-FileWatcher]
    N7[Start-LocalPSBite]
    N8[Start-RemotePSBite]
    N9[Start-RemotePSBiteEditor]
    N14[Test-PSBitePermission]
    N15[Write-PSBiteEditor]
    N11[Write-PSBiteMessage]
    N0 --> N5
    N0 --> N10
    N1 --> N7
    N1 --> N8
    N2 -.-> N11
    N3 -.-> N2
    N3 -.-> N12
    N3 -.-> N6
    N3 -.-> N11
    N4 -.-> N2
    N4 -.-> N12
    N4 -.-> N6
    N4 -.-> N11
    N5 -.-> N13
    N6 -.-> N11
    N7 -.-> N3
    N7 -.-> N6
    N7 -.-> N14
    N7 -.-> N15
    N7 -.-> N11
    N8 -.-> N9
    N8 -.-> N14
    N9 -.-> N4
    N9 -.-> N6
    N9 -.-> N15
    N9 -.-> N11

    style N0 fill:#4CAF50,stroke:#2E7D32,stroke-width:3px,color:#fff
    style N1 fill:#4CAF50,stroke:#2E7D32,stroke-width:3px,color:#fff
    style N2 fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style N3 fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style N4 fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style N13 fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style N12 fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style N5 fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style N6 fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style N10 fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style N7 fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style N8 fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style N9 fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style N14 fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style N15 fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style N11 fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
```

## 📊 Summary
- **Public functions**: 6
- **Private functions**: 14
- **Public → Private dependencies**: 4
- **Private → Private dependencies**: 22
- **Total dependencies detected**: 26

## 📋 Public → Private Dependencies

### 🔹 `Edit-RemoteFile`
Depends on:
- `Read-RemoteFile`
- `Start-FileWatcher`

### 🔹 `Start-PSBite`
Depends on:
- `Start-LocalPSBite`
- `Start-RemotePSBite`

## 🔗 Private → Private Dependencies

### 🔸 `Invoke-PSBiteKeyNavigation`
Depends on:
- `Write-PSBiteMessage`

### 🔸 `Invoke-PSBiteKeyPress`
Depends on:
- `Invoke-PSBiteKeyNavigation`
- `Read-PSBiteCommand`
- `Save-PSBiteFile`
- `Write-PSBiteMessage`

### 🔸 `Invoke-RemotePSBiteKeyPress`
Depends on:
- `Invoke-PSBiteKeyNavigation`
- `Read-PSBiteCommand`
- `Save-PSBiteFile`
- `Write-PSBiteMessage`

### 🔸 `Read-RemoteFile`
Depends on:
- `Read-FileWatcher`

### 🔸 `Save-PSBiteFile`
Depends on:
- `Write-PSBiteMessage`

### 🔸 `Start-LocalPSBite`
Depends on:
- `Invoke-PSBiteKeyPress`
- `Save-PSBiteFile`
- `Test-PSBitePermission`
- `Write-PSBiteEditor`
- `Write-PSBiteMessage`

### 🔸 `Start-RemotePSBite`
Depends on:
- `Start-RemotePSBiteEditor`
- `Test-PSBitePermission`

### 🔸 `Start-RemotePSBiteEditor`
Depends on:
- `Invoke-RemotePSBiteKeyPress`
- `Save-PSBiteFile`
- `Write-PSBiteEditor`
- `Write-PSBiteMessage`

## 📈 Statistics

### Most Used Private Functions
- `Write-PSBiteMessage`: referenced 6 time(s)
- `Save-PSBiteFile`: referenced 4 time(s)
- `Invoke-PSBiteKeyNavigation`: referenced 2 time(s)
- `Read-PSBiteCommand`: referenced 2 time(s)
- `Test-PSBitePermission`: referenced 2 time(s)

### Dependency Chain Analysis
- **Private functions with dependencies**: 8
- **Leaf private functions** (no dependencies): 6
