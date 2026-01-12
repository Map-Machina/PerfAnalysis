# PerfAnalysis Dashboard

Modern React-based frontend for the PerfAnalysis performance monitoring ecosystem.

## Tech Stack

- **React 18** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool
- **TailwindCSS** - Styling
- **TanStack Query** - Server state management
- **Zustand** - Client state management
- **Plotly.js** - Charts and visualizations
- **React Router** - Routing

## Getting Started

### Prerequisites

- Node.js 18+
- npm 9+

### Installation

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Start development server
npm run dev
```

The app will be available at http://localhost:3000

### Development

```bash
# Run development server
npm run dev

# Run linter
npm run lint

# Run tests
npm run test

# Run E2E tests
npm run test:e2e

# Build for production
npm run build
```

## Project Structure

```
src/
├── api/           # API client and endpoints
├── components/    # Reusable components
│   ├── charts/    # Chart components
│   ├── common/    # Shared UI components
│   ├── dashboard/ # Dashboard-specific
│   └── layout/    # Layout components
├── hooks/         # Custom React hooks
├── pages/         # Page components
├── store/         # Zustand stores
├── types/         # TypeScript definitions
└── utils/         # Utility functions
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `VITE_API_URL` | Backend API URL | `http://localhost:8000` |
| `VITE_ENABLE_CONTAINERS` | Enable container metrics | `true` |
| `VITE_ENABLE_REPORTS` | Enable report generation | `true` |

## Backend Integration

This frontend is designed to work with the XATbackend Django API. Ensure the backend is running and the `VITE_API_URL` is configured correctly.

## License

Copyright 2026 Business Performance Tuning. All rights reserved.
