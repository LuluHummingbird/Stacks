# Work Collaboration Smart Contract

A secure and efficient smart contract written in Clarity for the Stacks blockchain that enables decentralized collaboration on projects and tasks.

## Overview

This smart contract enables project owners to create, manage, and compensate contributors for completing tasks in a transparent and automated way. It provides a complete workflow for decentralized collaboration with built-in task tracking, contributor reputation, and automatic payment disbursement upon task completion.

## Key Features

- **Project Management**: Initialize projects with detailed information and track their status
- **Task Assignment**: Create and assign tasks with specific deadlines and rewards
- **Contributor System**: Register contributors, track their reputation, and manage their earnings
- **Work Submission**: Enable contributors to submit their work for review
- **Payment Processing**: Automatically release payments upon task approval
- **Reputation Building**: Build contributor reputation through successful task completions

## Contract Structure

The contract consists of several key components:

### Data Variables

- `contract-owner`: The principal who owns and administers the contract
- `project-name`: Name of the project (string, max 50 chars)
- `project-description`: Detailed description of the project (string, max 500 chars)
- `project-deadline`: Block height for project completion
- `project-budget`: Total budget allocated for the project
- `project-status`: Current project status ("not-started", "in-progress", "completed")

### Data Maps

- `tasks`: Stores task information with properties for name, description, status, deadline, reward, and assignment
- `contributors`: Tracks contributor information including role, reputation, completed tasks, and earnings
- `task-submissions`: Records task submissions with submission URL, timestamp, and approval status

### Helper Functions

- `validate-numeric-input`: Validates numeric inputs against minimum and maximum values
- `validate-string-input`: Validates string inputs against minimum and maximum lengths

### Public Functions

1. **initialize-project**: Sets up a new project with name, description, deadline, and budget
2. **create-task**: Creates a new task with specific parameters and reward amount
3. **register-contributor**: Allows users to register as contributors with specific roles
4. **assign-task**: Assigns a task to a registered contributor
5. **submit-task**: Allows contributors to submit completed work for review
6. **approve-submission**: Allows project owner to approve submissions and trigger payment

## Error Codes

- `400`: Invalid project status or operation
- `401`: Invalid deadline
- `402`: Invalid budget
- `403`: Unauthorized access (not contract owner)
- `404`: Resource not found
- `409`: Resource already exists
- `410`: Deadline violation (after project deadline)
- `411`: Invalid reward amount
- `412`: Invalid role
- `413`: Task deadline passed
- `414`: Invalid submission URL
- `415`: Submission after deadline
- `416`: Submitter mismatch
- `417`: Payment failure
- `420-424`: Various input validation errors

## Usage Flow

1. The contract is deployed with the deployer set as the contract owner
2. The owner initializes a project with parameters
3. The owner creates tasks with specific rewards
4. Contributors register with their roles
5. The owner assigns tasks to qualified contributors
6. Contributors submit their work along with a reference URL
7. The owner reviews submissions and approves completed tasks
8. Upon approval, payments are automatically released to contributors

## Security Features

The contract includes comprehensive security measures:

- Extensive input validation for all function parameters
- Role-based access control for sensitive operations
- Transaction validation to prevent unauthorized modifications
- Explicit handling of potentially unchecked data
- Clear error reporting with specific error codes
- Deadline enforcement for tasks and submissions

## Example Usage

### Initialize a Project

```clarity
(contract-call? .work-collaboration initialize-project "Web3 Marketplace" "Build a decentralized marketplace for digital goods" u100000 u1000000)
```

### Create a Task

```clarity
(contract-call? .work-collaboration create-task u1 "Frontend UI" "Create responsive user interface with React" u90000 u100000)
```

### Register as a Contributor

```clarity
(contract-call? .work-collaboration register-contributor "Frontend Developer")
```

### Assign a Task

```clarity
(contract-call? .work-collaboration assign-task u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Submit Work

```clarity
(contract-call? .work-collaboration submit-task u1 "https://github.com/user/repo/pull/123")
```

### Approve Submission

```clarity
(contract-call? .work-collaboration approve-submission u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## Deployment Requirements

- Stacks 2.0 or later blockchain
- Sufficient STX for contract deployment and task rewards