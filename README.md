# Blockchain-Based Marine Ecosystem Protection

A comprehensive blockchain solution for protecting marine ecosystems through transparent monitoring, regulation, and funding mechanisms built on the Stacks blockchain using Clarity smart contracts.

## 🌊 Overview

This project implements a decentralized system for marine conservation that includes:

- **Marine Area Verification**: Validates and manages ocean conservation zones
- **Ecosystem Monitoring**: Tracks marine biodiversity and ecosystem health
- **Fishing Regulation**: Manages sustainable fishing practices and quotas
- **Pollution Tracking**: Monitors ocean contamination and pollution sources
- **Conservation Funding**: Manages marine protection financing and grants

## 📋 Features

### Marine Area Verification
- Register new marine conservation areas
- Verify protected zones with coordinates and protection levels
- Update protection status and management details
- Track area size and conservation metrics

### Ecosystem Monitoring
- Record biodiversity data (species count, coral coverage)
- Monitor water quality and pollution levels
- Track fish population changes over time
- Authorize scientific monitors and researchers

### Fishing Regulation
- Issue fishing licenses with quotas and restrictions
- Record catch data and enforce sustainable limits
- Implement area-based fishing restrictions
- Track quota usage and compliance

### Pollution Tracking
- Report pollution incidents with location data
- Verify and track cleanup efforts
- Monitor pollution sources and risk levels
- Coordinate response efforts

### Conservation Funding
- Create funding proposals for conservation projects
- Manage donation pools and grant distribution
- Track funding progress and project completion
- Ensure transparent fund allocation

## 🏗️ Smart Contract Architecture

### Core Contracts

1. **marine-area-verification.clar**
    - Manages marine protected areas
    - Handles area registration and verification
    - Tracks protection levels and boundaries

2. **ecosystem-monitoring.clar**
    - Records ecosystem health data
    - Manages authorized monitors
    - Tracks biodiversity metrics

3. **fishing-regulation.clar**
    - Issues and manages fishing licenses
    - Enforces quotas and restrictions
    - Records catch data

4. **pollution-tracking.clar**
    - Handles pollution reporting
    - Tracks cleanup efforts
    - Manages pollution sources

5. **conservation-funding.clar**
    - Manages funding proposals
    - Handles donations and grants
    - Tracks project funding

## 🚀 Getting Started

### Prerequisites
- Stacks blockchain development environment
- Clarity CLI tools
- Node.js for testing

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd marine-ecosystem-protection
```

2. Install dependencies:
```bash
npm install
```

3. Deploy contracts to testnet:
```bash
clarinet deploy --testnet
```

### Usage Examples

#### Register a Marine Area
```clarity
(contract-call? .marine-area-verification register-marine-area 
  "Great Barrier Reef Section A" 
  -16500000  ;; latitude (scaled by 1e6)
  145800000  ;; longitude (scaled by 1e6)
  u1000      ;; size in km²
  "strict"   ;; protection level
)
```

#### Record Ecosystem Data
```clarity
(contract-call? .ecosystem-monitoring record-ecosystem-data
  u1         ;; area-id
  u150       ;; species count
  u85        ;; water quality (1-100)
  u75        ;; coral coverage percentage
  u1200      ;; fish population estimate
  u3         ;; pollution level (1-10)
)
```

#### Issue Fishing License
```clarity
(contract-call? .fishing-regulation issue-fishing-license
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM  ;; license holder
  u1         ;; area-id
  "tuna"     ;; species
  u500       ;; quota in kg
  u8760      ;; valid for ~1 year (blocks)
)
```

#### Report Pollution
```clarity
(contract-call? .pollution-tracking report-pollution
  u1                    ;; area-id
  "plastic"            ;; pollution type
  u7                   ;; severity (1-10)
  "shipping vessel"    ;; source
  -16500000           ;; latitude
  145800000           ;; longitude
