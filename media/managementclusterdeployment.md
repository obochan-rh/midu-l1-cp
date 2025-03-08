```mermaid
graph TD
    A[Prerequisites] --> B[AirGapped Registry]
    A --> C[AirGapped HTTP(s) Server]
    A --> D[Git-Server]
    A --> E[DNS-Server]
    
    B --> F[Download Binaries]
    C --> F
    D --> F
    E --> F

    F --> G[Download Pre-requisites Binaries]
    G --> H[Mirroring OCI Content]
    H --> I[OCI Content to AirGapped Registry]
    I --> J[Download RHCOS]
    J --> K[Agent-based Installer]
    K --> L[Hub Configuration]
    L --> M[Spoke Deployment]
    
    M --> N[Troubleshooting]
    N --> O[Conclusions]
