# Test Infrastructure for azure-network-security-integrity

This directory contains testing infrastructure for the azure-network-security-integrity codebundle.

## Structure

- **README.md**: This file
- **terraform/**: Terraform configurations for test resources (if needed)
- **test_data/**: Sample data for testing
- **scripts/**: Test automation scripts

## Usage

This test infrastructure is designed to validate the codebundle functionality in a controlled environment.

### Prerequisites

- Appropriate cloud credentials configured
- Test environment access
- Required CLI tools installed

### Running Tests

```bash
# Navigate to the codebundle directory
cd codebundles/azure-network-security-integrity

# Run the runbook for testing
ro runbook.robot

# Run the SLI for testing  
ro sli.robot
```

## Test Data

Test data should be placed in the `test_data/` directory and should include:

- Sample configuration files
- Mock API responses
- Expected output examples

## Automation

Test automation scripts should:

- Set up test resources
- Execute the codebundle
- Validate outputs
- Clean up resources

---

*Auto-generated test infrastructure*
