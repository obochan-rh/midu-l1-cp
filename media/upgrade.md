```mermaid
graph TD
    A[Upgrade Preparation] --> B[Start: Initiate Upgrade]
    B --> C[Pre-Upgrade Validation]
    C --> D{Rolling Upgrade?}
    
    D -- Yes --> E[Backup & Snapshot - Rolling]
    E --> F[Initiate TALM Rolling Upgrade]
    F --> G[Monitor Upgrade Progress]
    G --> H[Validate Upgrade Completion]
    H --> I[Post-Upgrade Checks]
    
    D -- No --> J[Backup & Snapshot - Non-Rolling]
    J --> K[Upgrade Execution]
    K --> L[Validate Upgrade Completion]
    L --> M[Post-Upgrade Checks]

    I --> N[End]
    M --> N
