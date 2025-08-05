# Blockchain-Based Public Consumer Protection Services

A comprehensive smart contract system built on the Stacks blockchain to provide transparent, immutable consumer protection services. This system enables government agencies and consumer protection organizations to manage business licenses, process complaints, monitor pricing, coordinate recalls, and prevent financial fraud.

## System Overview

This system consists of five interconnected smart contracts that work together to provide comprehensive consumer protection:

### 1. Business License Verification Contract (`business-license.clar`)
- Tracks valid business licenses and permits
- Manages license issuance, renewal, and revocation
- Provides public verification of business legitimacy
- Maintains license expiration tracking

### 2. Consumer Complaint Processing Contract (`consumer-complaints.clar`)
- Manages complaints against businesses and service providers
- Tracks complaint status and resolution
- Maintains complaint history and patterns
- Enables public transparency in business practices

### 3. Price Monitoring and Fraud Detection Contract (`price-monitoring.clar`)
- Identifies unfair pricing and deceptive business practices
- Tracks price changes and market manipulation
- Flags suspicious pricing patterns
- Maintains historical pricing data

### 4. Product Safety Recall Coordination Contract (`product-recalls.clar`)
- Manages recalls of dangerous consumer products
- Coordinates recall notifications and tracking
- Maintains recall history and affected product lists
- Enables rapid consumer notification

### 5. Financial Fraud Prevention Contract (`financial-fraud.clar`)
- Protects consumers from predatory lending and financial scams
- Tracks fraudulent financial entities
- Manages fraud alerts and warnings
- Maintains blacklists of known fraudulent actors

## Key Features

- **Immutable Records**: All consumer protection data is stored on-chain for transparency
- **Public Verification**: Anyone can verify business licenses and check complaint histories
- **Automated Alerts**: Smart contracts can trigger alerts for recalls and fraud warnings
- **Decentralized Governance**: Multiple authorized entities can contribute to the system
- **Historical Tracking**: Complete audit trails for all consumer protection activities

## Contract Architecture

Each contract is designed to be independent while sharing common patterns:
- Role-based access control for authorized entities
- Event logging for transparency
- Data validation and error handling
- Public read functions for consumer access
- Administrative functions for authorized updates

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for deployment

### Installation

\`\`\`bash
git clone <repository-url>
cd consumer-protection-blockchain
npm install
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Verify Business License
\`\`\`clarity
(contract-call? .business-license get-license-status "BUSINESS-123")
\`\`\`

### File Consumer Complaint
\`\`\`clarity
(contract-call? .consumer-complaints file-complaint "BUSINESS-123" "Poor service quality" u1)
\`\`\`

### Check Product Recalls
\`\`\`clarity
(contract-call? .product-recalls get-active-recalls)
\`\`\`

## Security Considerations

- All contracts implement proper access controls
- Input validation prevents malicious data entry
- Rate limiting prevents spam and abuse
- Multi-signature requirements for critical operations

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
