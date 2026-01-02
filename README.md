# BitStake Protocol

**Decentralized sBTC Staking Platform on Stacks Layer 2**

BitStake Protocol is a Bitcoin Layer 2 staking solution that enables sBTC holders to earn yield through time-locked staking mechanisms. Built on Stacks blockchain, it leverages Bitcoin's security and finality to provide a trustless staking experience.

## 🚀 Key Features

- **Flexible Staking**: Stake any amount of sBTC with configurable lock periods
- **Dynamic Rewards**: Earn rewards based on staking duration and participation
- **Bitcoin Security**: Inherits Bitcoin's security through Stacks Layer 2
- **Transparent Governance**: Owner-managed protocol parameters with clear visibility
- **Reward Claiming**: Claim rewards independently without unstaking
- **Emergency Unstaking**: Unstake with automatic reward distribution

## 📊 System Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│                 │    │                  │    │                 │
│   sBTC Holders  │◄──►│ BitStake Protocol│◄──►│  Reward Pool    │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│                 │    │                  │    │                 │
│  Stake Records  │    │  Smart Contract  │    │ sBTC Transfers  │
│                 │    │   (Clarity)      │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Core Components

1. **Staking Engine**: Manages user stakes and calculates time-based rewards
2. **Reward Distribution**: Handles reward pool management and payouts  
3. **Governance Layer**: Administrative controls for protocol parameters
4. **Token Interface**: Integrates with sBTC token contract for transfers

## 🏗️ Contract Architecture

### Data Storage Layer

```
Stakes Map
┌─────────────────────────────────────┐
│ Key: { staker: principal }          │
│ Value: {                            │
│   amount: uint,                     │
│   staked-at: uint                   │
│ }                                   │
└─────────────────────────────────────┘

Rewards Claimed Map
┌─────────────────────────────────────┐
│ Key: { staker: principal }          │
│ Value: { amount: uint }             │
└─────────────────────────────────────┘

Protocol Variables
┌─────────────────────────────────────┐
│ • reward-rate (basis points)        │
│ • reward-pool (total available)     │
│ • min-stake-period (blocks)         │
│ • total-staked (protocol TVL)       │
│ • contract-owner (admin)            │
└─────────────────────────────────────┘
```

### Function Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Administrative Layer                     │
├─────────────────────────────────────────────────────────────┤
│ • set-contract-owner()     • set-reward-rate()             │
│ • set-min-stake-period()   • add-to-reward-pool()          │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                     Core Staking Layer                     │
├─────────────────────────────────────────────────────────────┤
│ • stake()                  • unstake()                     │
│ • claim-rewards()          • calculate-rewards()           │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                     Query Interface Layer                  │
├─────────────────────────────────────────────────────────────┤
│ • get-stake-info()         • get-protocol-stats()          │
│ • get-rewards-claimed()    • get-current-apy()             │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow

### Staking Flow

```
User Initiates Stake
        │
        ▼
Validate Amount > 0
        │
        ▼
Transfer sBTC to Contract
        │
        ▼
Update/Create Stake Record
        │
        ▼
Update Total Staked
        │
        ▼
Return Success
```

### Reward Calculation Flow

```
Calculate Rewards Request
        │
        ▼
Fetch Stake Information
        │
        ▼
Calculate Duration (current_block - staked_at)
        │
        ▼
Apply Reward Formula:
reward = (stake_amount × reward_rate / 1000) × (duration / blocks_per_year)
        │
        ▼
Return Calculated Reward
```

### Unstaking Flow

```
User Initiates Unstake
        │
        ▼
Validate Conditions:
• Amount > 0
• Sufficient Stake
• Min Period Met
        │
        ▼
Claim Pending Rewards
        │
        ▼
Update Stake Record
        │
        ▼
Transfer sBTC to User
        │
        ▼
Update Total Staked
        │
        ▼
Return Success
```

## 🛠️ Getting Started

### Prerequisites

- Stacks blockchain environment
- sBTC tokens for staking
- Clarinet for local development (optional)

### Deployment

```bash
# Deploy to Stacks testnet
clarinet deploy --testnet

# Deploy to Stacks mainnet
clarinet deploy --mainnet
```

### Basic Usage

#### Stake sBTC

```lisp
(contract-call? .bitstake-protocol stake u1000000) ;; Stake 1 sBTC
```

#### Check Rewards

```lisp
(contract-call? .bitstake-protocol calculate-rewards 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX975CN2QKH)
```

#### Claim Rewards

```lisp
(contract-call? .bitstake-protocol claim-rewards)
```

#### Unstake

```lisp
(contract-call? .bitstake-protocol unstake u500000) ;; Unstake 0.5 sBTC
```

## 📈 Protocol Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| Reward Rate | 5 basis points (0.5%) | Annual reward rate |
| Min Stake Period | 1440 blocks (~10 days) | Minimum lock period |
| Max Reward Rate | 1000 basis points (100%) | Safety cap |

## 🔐 Security Features

- **Access Control**: Administrative functions restricted to contract owner
- **Input Validation**: Comprehensive parameter validation on all functions
- **Overflow Protection**: Safe arithmetic operations throughout
- **Minimum Lock Period**: Prevents gaming through rapid stake/unstake cycles
- **Reward Pool Management**: Ensures sufficient rewards before distribution

## 📝 Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR_NOT_AUTHORIZED | Caller lacks required permissions |
| u101 | ERR_ZERO_STAKE | Invalid zero amount provided |
| u102 | ERR_NO_STAKE_FOUND | No active stake for user |
| u103 | ERR_TOO_EARLY_TO_UNSTAKE | Minimum stake period not met |
| u104 | ERR_INVALID_REWARD_RATE | Reward rate exceeds maximum |
| u105 | ERR_NOT_ENOUGH_REWARDS | Insufficient reward pool balance |
| u106 | ERR_INVALID_PERIOD | Invalid time period specified |
| u107 | ERR_OWNER_UNCHANGED | New owner same as current owner |

## 🤝 Contributing

We welcome contributions to BitStake Protocol! Please read our contributing guidelines and submit pull requests for any improvements.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚠️ Disclaimer

BitStake Protocol is experimental software. Use at your own risk. Always do your own research before staking any assets.
