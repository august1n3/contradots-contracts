# UI Requirements for Activity Action Tracker System

## Overview

This document outlines the requirements for building a user interface to interact with the Activity Action Tracker smart contracts. The UI should provide an intuitive experience for creating activities, submitting actions, validating proofs, and tracking reputation scores.

## Contract Information

### Deployed Contracts
- **ActivityActionTracker**: `<ACTIVITY_TRACKER_ADDRESS>`
- **ReputationTracker**: `<REPUTATION_TRACKER_ADDRESS>`

### Network Configuration
- Network: [Ethereum Mainnet / Testnet / Local]
- RPC URL: `<RPC_URL>`
- Chain ID: `<CHAIN_ID>`

## Core Features Required

### 1. Wallet Connection

**Requirements:**
- Support MetaMask, WalletConnect, and Coinbase Wallet
- Display connected wallet address
- Show current network
- Handle network switching
- Disconnect functionality

**User Flow:**
```
┌─────────────┐
│ Connect     │
│ Wallet      │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Select      │
│ Provider    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Connected   │
│ Dashboard   │
└─────────────┘
```

### 2. Activity Management

#### 2.1 Create Activity (Admin/Lead Only)

**Form Fields:**
- Activity Name (string, max 32 bytes)
- Description (string, max 32 bytes)
- Lead Person ID (uint256)
- Reputation Points (uint256)

**Validation:**
- Name: Required, 1-32 characters
- Description: Required, 1-256 characters
- Lead ID: Required, positive integer
- Points: Required, 1-1000 range

**UI Elements:**
```
┌──────────────────────────────────┐
│ Create New Activity              │
├──────────────────────────────────┤
│ Activity Name: [_______________] │
│ Description:  [_______________]  │
│ Lead Person ID: [______________] │
│ Points Reward: [_______________] │
│                                  │
│ [Cancel] [Create Activity]       │
└──────────────────────────────────┘
```

**Success/Error Handling:**
- Show transaction hash on success
- Display activity ID
- Handle gas estimation failures
- Show user-friendly error messages

#### 2.2 View Activities

**Display Information:**
- Activity ID
- Name
- Description
- Lead Person ID
- Points awarded
- Active status
- Actions submitted count
- Actions validated count

**Features:**
- List view with pagination (10-25 items per page)
- Search by name
- Filter by:
  - Status (Active/Inactive)
  - Points range
  - Lead ID
- Sort by:
  - Created date (newest/oldest)
  - Points (highest/lowest)
  - Name (A-Z)

**UI Layout:**
```
┌────────────────────────────────────────────────────┐
│ Activities                    [+ Create Activity]  │
├────────────────────────────────────────────────────┤
│ Search: [_____________] 🔍                         │
│ Filter: [Active ▼] Points: [0-100 ▼] Sort: [▼]   │
├────────────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────────┐  │
│ │ 🎯 Beach Cleanup            50 pts   Active  │  │
│ │ ID: 1 | Lead: Person #1                      │  │
│ │ Clean local beach and collect trash          │  │
│ │ Actions: 5 submitted, 3 validated            │  │
│ │ [View Details] [Deactivate]                  │  │
│ └──────────────────────────────────────────────┘  │
│                                                    │
│ ┌──────────────────────────────────────────────┐  │
│ │ 🌳 Tree Planting           100 pts   Active  │  │
│ │ ID: 2 | Lead: Person #1                      │  │
│ │ Plant trees in the community park            │  │
│ │ Actions: 12 submitted, 8 validated           │  │
│ │ [View Details] [Deactivate]                  │  │
│ └──────────────────────────────────────────────┘  │
│                                                    │
│ Page 1 of 5  [< Prev] [Next >]                    │
└────────────────────────────────────────────────────┘
```

#### 2.3 Activity Details Page

**Display:**
- Full activity information
- List of all submitted actions
- Timeline of validations
- Participants list with reputation earned

**Actions Available:**
- Submit action (for participants)
- Deactivate activity (for admin/lead)
- View action details

### 3. Action Submission

**Form Fields:**
- Person ID (pre-filled from wallet or manual entry)
- Activity Selection (dropdown)
- Description of work done (textarea)
- Proof Upload (file/hash)

**Validation:**
- Person ID: Required, positive integer
- Activity: Must be active
- Description: Required, 1-256 characters
- Proof: Required, hash or file (converted to hash)

**UI Elements:**
```
┌──────────────────────────────────────┐
│ Submit Action                        │
├──────────────────────────────────────┤
│ Your Person ID: [2____________]      │
│                                      │
│ Select Activity:                     │
│ [Beach Cleanup (50 pts) ▼]          │
│                                      │
│ Describe what you did:               │
│ [_________________________________]  │
│ [_________________________________]  │
│ [_________________________________]  │
│                                      │
│ Upload Proof (Photo/Document):       │
│ ┌────────────────────────────────┐  │
│ │ Drag & drop or [Browse Files]  │  │
│ │ Supported: JPG, PNG, PDF       │  │
│ │ Max size: 10MB                 │  │
│ └────────────────────────────────┘  │
│                                      │
│ Or enter proof hash:                 │
│ [_________________________________]  │
│                                      │
│ [Cancel] [Submit Action]             │
└──────────────────────────────────────┘
```

**Proof Handling:**
- Option 1: Upload file → Hash on client-side → Submit hash
- Option 2: Store file on IPFS → Submit IPFS hash
- Option 3: Manual hash entry

**Post-Submission:**
- Show action ID
- Display pending status
- Show transaction hash
- Add to user's action history

### 4. Action Validation (Lead/Admin Only)

**View Pending Actions:**
- List of all pending actions for activities they lead
- Filter by activity
- Sort by submission date

**Action Details Display:**
- Submitter Person ID
- Activity name
- Description
- Proof hash (with link to view if IPFS)
- Submission timestamp

**Validation UI:**
```
┌──────────────────────────────────────────────┐
│ Pending Action #1                            │
├──────────────────────────────────────────────┤
│ Activity: Beach Cleanup (50 pts)             │
│ Submitted by: Person #42                     │
│ Date: 2024-01-15 14:30                       │
│                                              │
│ Description:                                 │
│ "Collected 10 bags of trash from the beach   │
│ and properly disposed of them."              │
│                                              │
│ Proof:                                       │
│ Hash: 0x123abc...789def                      │
│ [View Proof] 🔗                              │
│                                              │
│ ┌──────────────────────────────────────────┐│
│ │ Validate this action?                    ││
│ │                                          ││
│ │ ✅ Accept (+50 pts)                      ││
│ │ ❌ Reject (-25 pts penalty)              ││
│ └──────────────────────────────────────────┘│
│                                              │
│ Note: This action cannot be undone.          │
│                                              │
│ [Skip] [Reject] [Approve]                    │
└──────────────────────────────────────────────┘
```

**Batch Validation:**
- Select multiple actions
- Bulk approve/reject
- Confirmation modal before submission

### 5. Reputation Dashboard

#### 5.1 Personal Reputation View

**Display:**
- Current total reputation score
- Reputation history chart
- Recent actions (submitted, validated, rejected)
- Activities participated in
- Badges/achievements (optional)

**UI Layout:**
```
┌────────────────────────────────────────────┐
│ Your Reputation                            │
├────────────────────────────────────────────┤
│ Total Score: 450 pts                       │
│ Rank: #23 of 156 users                     │
│                                            │
│ ┌────────────────────────────────────────┐│
│ │     Reputation Over Time               ││
│ │ 500│                                   ││
│ │    │                     ╱─            ││
│ │ 400│                ╱───╯              ││
│ │    │           ╱───╯                   ││
│ │ 300│      ╱───╯                        ││
│ │    │ ╱───╯                             ││
│ │ 200│╯                                  ││
│ │    └───────────────────────────────────││
│ │     Jan  Feb  Mar  Apr  May  Jun      ││
│ └────────────────────────────────────────┘│
│                                            │
│ Recent Activity:                           │
│ ✅ Beach Cleanup validated    +50 pts     │
│ ⏳ Tree Planting pending                  │
│ ❌ Code Review rejected       -25 pts     │
│                                            │
│ [View Full History]                        │
└────────────────────────────────────────────┘
```

#### 5.2 Leaderboard

**Display:**
- Top users by reputation
- Search for specific user
- Filter by time period (all-time, monthly, weekly)

**UI Layout:**
```
┌─────────────────────────────────────────┐
│ 🏆 Reputation Leaderboard               │
├─────────────────────────────────────────┤
│ Filter: [All Time ▼]                    │
├─────────────────────────────────────────┤
│ Rank | Person ID | Score | Actions      │
├─────────────────────────────────────────┤
│  1   | Person #7  | 2,450 | 49          │
│  2   | Person #23 | 2,100 | 42          │
│  3   | Person #15 | 1,890 | 38          │
│  4   | Person #42 | 1,750 | 35          │
│ ...                                     │
│  23  | Person #2  |   450 | 9  ← You    │
│ ...                                     │
└─────────────────────────────────────────┘
```

### 6. User Profile/Settings

**Features:**
- Link Person ID to wallet address
- Set notification preferences
- View transaction history
- Export activity data (CSV/JSON)

**UI Elements:**
```
┌──────────────────────────────────────┐
│ Profile Settings                     │
├──────────────────────────────────────┤
│ Wallet: 0x1234...5678               │
│ Person ID: [2____________]          │
│                                      │
│ Notifications:                       │
│ ☑ Action validated                  │
│ ☑ New activity created              │
│ ☐ Leaderboard position change       │
│                                      │
│ Data Export:                         │
│ [Export Actions CSV]                 │
│ [Export Reputation History]          │
│                                      │
│ [Save Changes]                       │
└──────────────────────────────────────┘
```

