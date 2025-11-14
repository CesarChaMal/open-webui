# CLAUDE.md - AI Assistant Guide for Open WebUI

This document provides comprehensive guidance for AI assistants (like Claude) working with the Open WebUI codebase. It covers architecture, conventions, workflows, and best practices.

## Table of Contents

- [Project Overview](#project-overview)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Development Environment Setup](#development-environment-setup)
- [Architecture & Design Patterns](#architecture--design-patterns)
- [Code Conventions & Standards](#code-conventions--standards)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Key Concepts](#key-concepts)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)

---

## Project Overview

**Open WebUI** (version 0.6.5) is an extensible, feature-rich, and user-friendly self-hosted AI platform designed to operate entirely offline. It provides a web interface for interacting with various LLM providers.

### Key Features
- Support for Ollama and OpenAI-compatible APIs
- Built-in RAG (Retrieval Augmented Generation) capabilities
- Multi-model conversations
- Native Python function calling
- Image generation integration
- Audio/video capabilities
- Multi-language support (i18n)
- Plugin/Pipeline architecture
- Role-based access control (RBAC)

### Project Links
- **Repository**: https://github.com/open-webui/open-webui
- **Documentation**: https://docs.openwebui.com/
- **Discord**: https://discord.gg/5rJgQTnV4s
- **Community**: https://openwebui.com/

---

## Tech Stack

### Frontend
- **Framework**: SvelteKit 2.x (with Svelte 4.2.x)
- **Language**: TypeScript 5.5.x (strict mode enabled)
- **Build Tool**: Vite 5.x
- **Styling**: Tailwind CSS 4.x with custom configuration
- **UI Components**:
  - bits-ui (component primitives)
  - TipTap (rich text editor)
  - CodeMirror (code editing)
  - Mermaid (diagrams)
- **State Management**: Svelte stores
- **API Client**: Custom fetch-based API layer
- **i18n**: i18next with browser language detection

### Backend
- **Framework**: FastAPI 0.115.x
- **Language**: Python 3.11 (required)
- **Web Server**: Uvicorn with standard extras
- **ORM**: SQLAlchemy 2.0.x with Alembic migrations
- **Alternative ORM**: Peewee 3.17.x (legacy support)
- **Databases**: PostgreSQL, MySQL, SQLite (default), MongoDB
- **Vector DBs**: ChromaDB, Milvus, Qdrant, OpenSearch, Elasticsearch
- **Authentication**:
  - python-jose (JWT)
  - passlib with bcrypt
  - OAuth support (LDAP, Azure, Google)
- **AI/ML Libraries**:
  - OpenAI SDK
  - Anthropic SDK
  - Google Generative AI
  - LangChain & LangChain Community
  - Transformers & Sentence Transformers
  - Faster Whisper (audio)
  - Various embedding models
- **Task Queue**: APScheduler
- **Real-time**: python-socketio
- **Document Processing**: pypdf, python-pptx, docx2txt, unstructured
- **Testing**: pytest with docker support

### DevOps & Tooling
- **Containerization**: Docker with multi-stage builds
- **Orchestration**: Kubernetes (Helm charts & manifests available)
- **Linting**:
  - ESLint (frontend)
  - Pylint (backend)
- **Formatting**:
  - Prettier (frontend)
  - Black (backend)
- **Testing**:
  - Vitest (frontend unit tests)
  - Cypress (e2e tests)
  - pytest (backend tests)
- **CI/CD**: GitHub Actions workflows

---

## Repository Structure

```
open-webui/
├── backend/                    # Python FastAPI backend
│   ├── open_webui/            # Main backend package
│   │   ├── __init__.py
│   │   ├── main.py            # FastAPI application entry point
│   │   ├── config.py          # Configuration management
│   │   ├── constants.py       # Constants and enums
│   │   ├── env.py             # Environment variable handling
│   │   ├── functions.py       # Utility functions
│   │   ├── tasks.py           # Background task definitions
│   │   ├── routers/           # API route handlers
│   │   │   ├── audio.py       # Audio processing endpoints
│   │   │   ├── auths.py       # Authentication endpoints
│   │   │   ├── chats.py       # Chat management
│   │   │   ├── files.py       # File upload/management
│   │   │   ├── functions.py   # Function calling
│   │   │   ├── images.py      # Image generation
│   │   │   ├── knowledge.py   # Knowledge base
│   │   │   ├── ollama.py      # Ollama integration
│   │   │   ├── openai.py      # OpenAI API integration
│   │   │   ├── pipelines.py   # Pipeline management
│   │   │   ├── retrieval.py   # RAG endpoints
│   │   │   ├── tasks.py       # Task endpoints
│   │   │   ├── tools.py       # Tool management
│   │   │   └── users.py       # User management
│   │   ├── models/            # Database models (SQLAlchemy & Pydantic)
│   │   ├── internal/          # Internal utilities
│   │   ├── migrations/        # Alembic database migrations
│   │   ├── retrieval/         # RAG implementation
│   │   ├── socket/            # WebSocket handlers
│   │   ├── storage/           # File storage abstractions
│   │   ├── static/            # Static backend files
│   │   ├── utils/             # Utility modules
│   │   └── test/              # Backend tests
│   ├── requirements.txt       # Python dependencies
│   ├── dev.sh                 # Development startup script
│   └── start.sh               # Production startup script
├── src/                       # SvelteKit frontend source
│   ├── lib/                   # Shared library code
│   │   ├── apis/              # API client modules (mirrors backend routers)
│   │   │   ├── index.ts       # Main API exports
│   │   │   ├── audio/
│   │   │   ├── auths/
│   │   │   ├── chats/
│   │   │   ├── ollama/
│   │   │   ├── openai/
│   │   │   └── ...            # (matches backend routers)
│   │   ├── components/        # Reusable Svelte components
│   │   ├── i18n/              # Internationalization
│   │   │   └── locales/       # Translation files (en-US, fr-FR, etc.)
│   │   ├── stores/            # Svelte stores (state management)
│   │   ├── types/             # TypeScript type definitions
│   │   ├── utils/             # Utility functions
│   │   ├── workers/           # Web Workers
│   │   ├── pyodide/           # Pyodide integration
│   │   └── constants.ts       # Frontend constants
│   ├── routes/                # SvelteKit routes
│   │   ├── (app)/             # Main app routes (authenticated)
│   │   │   ├── admin/         # Admin panel
│   │   │   ├── c/             # Chat routes
│   │   │   ├── channels/      # Channel management
│   │   │   ├── home/          # Home page
│   │   │   ├── playground/    # Playground feature
│   │   │   └── workspace/     # Workspace (tools, functions, etc.)
│   │   ├── auth/              # Authentication pages
│   │   ├── error/             # Error pages
│   │   ├── s/                 # Share routes
│   │   ├── watch/             # Watch feature
│   │   ├── +layout.svelte     # Root layout
│   │   ├── +layout.js         # Root layout logic
│   │   └── +page.svelte       # Root page
│   ├── app.html               # HTML template
│   ├── app.css                # Global styles
│   └── app.d.ts               # TypeScript declarations
├── static/                    # Static assets
│   ├── audio/                 # Audio files
│   ├── themes/                # Theme files
│   ├── assets/                # Images, icons, etc.
│   └── pyodide/               # Pyodide distribution files
├── cypress/                   # Cypress e2e tests
│   ├── e2e/                   # Test specs
│   └── support/               # Test support files
├── docs/                      # Documentation
│   ├── CONTRIBUTING.md        # Contribution guidelines
│   ├── SECURITY.md            # Security policy
│   └── apache.md              # Apache deployment guide
├── kubernetes/                # Kubernetes deployment configs
│   ├── helm/                  # Helm charts
│   └── manifest/              # Raw manifests
├── test/                      # Test files and fixtures
├── .github/                   # GitHub configuration
│   ├── workflows/             # CI/CD workflows
│   └── ISSUE_TEMPLATE/        # Issue templates
├── Dockerfile                 # Multi-stage Docker build
├── docker-compose.yaml        # Docker Compose configuration
├── package.json               # Node.js dependencies & scripts
├── tsconfig.json              # TypeScript configuration
├── vite.config.ts             # Vite build configuration
├── svelte.config.js           # SvelteKit configuration
├── tailwind.config.js         # Tailwind CSS configuration
├── .eslintrc.cjs              # ESLint configuration
└── .gitignore                 # Git ignore rules
```

---

## Development Environment Setup

### Prerequisites
- **Node.js**: 18.13.0 - 22.x.x
- **npm**: >= 6.0.0
- **Python**: 3.11 (strictly required)
- **Docker** (optional but recommended)

### Local Development Setup

#### Frontend Only
```bash
# Install dependencies
npm ci

# Start development server (with Pyodide fetch)
npm run dev

# Or on port 5050
npm run dev:5050

# Build for production
npm run build

# Preview production build
npm preview
```

#### Backend Only
```bash
cd backend

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run development server
./dev.sh  # On Windows: start_windows.bat
```

#### Full Stack Development
```bash
# Terminal 1: Start backend
cd backend && ./dev.sh

# Terminal 2: Start frontend
npm run dev
```

#### Docker Development
```bash
# Basic development container
docker-compose up

# With GPU support
docker-compose -f docker-compose.yaml -f docker-compose.gpu.yaml up

# With Playwright testing
docker-compose -f docker-compose.yaml -f docker-compose.playwright.yaml up
```

### Environment Variables

Key environment variables (create `.env` in root or `backend/`):

```bash
# Backend API URL (for frontend)
VITE_API_BASE_URL=http://localhost:8080

# Database
DATABASE_URL=sqlite:///./data/webui.db
# Or PostgreSQL: postgresql://user:pass@localhost/dbname

# Ollama
OLLAMA_BASE_URL=http://localhost:11434
ENABLE_OLLAMA_API=true

# OpenAI
OPENAI_API_KEY=your_key_here
OPENAI_API_BASE_URL=https://api.openai.com/v1

# Security
WEBUI_SECRET_KEY=your_secret_key
JWT_SECRET_KEY=your_jwt_secret

# Features
ENABLE_RAG=true
RAG_EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
WHISPER_MODEL=base

# Telemetry (disable in dev)
DO_NOT_TRACK=true
ANONYMIZED_TELEMETRY=false
SCARF_NO_ANALYTICS=true
```

---

## Architecture & Design Patterns

### Frontend Architecture

#### SvelteKit Structure
- **Routes**: File-based routing in `src/routes/`
- **Layout Hierarchy**:
  - Root layout (`+layout.svelte`)
  - App layout (`(app)/+layout.svelte`) for authenticated routes
  - Route-specific layouts
- **API Layer**: Centralized in `src/lib/apis/` mirroring backend structure
- **State Management**: Svelte stores in `src/lib/stores/`
- **Components**: Reusable components in `src/lib/components/`

#### Key Frontend Patterns
1. **API Client Pattern**: Each backend router has a corresponding frontend API module
2. **Store Pattern**: Reactive stores for global state (user, settings, models, etc.)
3. **Component Composition**: Small, focused components composed into larger features
4. **Type Safety**: TypeScript interfaces for all data structures
5. **i18n Pattern**: Translation keys organized by feature area

### Backend Architecture

#### FastAPI Structure
- **Main Application**: `backend/open_webui/main.py`
- **Router Organization**: Feature-based routers in `routers/`
- **Database Models**: SQLAlchemy models in `models/`
- **Pydantic Schemas**: Request/response validation
- **Dependency Injection**: FastAPI's DI for database sessions, auth, etc.

#### Key Backend Patterns
1. **Router Pattern**: Each feature domain has its own router
2. **Repository Pattern**: Database access through model classes
3. **Service Layer**: Business logic separated from routes (in some areas)
4. **Middleware Stack**: CORS, sessions, audit logging
5. **Plugin Architecture**: Pipelines for extensibility

### Database Architecture

#### Models Organization
- **User Management**: `models/users.py`
- **Chat System**: `models/chats.py`
- **Document/Knowledge**: `models/knowledge.py`
- **Functions/Tools**: `models/functions.py`, `models/tools.py`
- **Configuration**: Various config models

#### Migration Strategy
- **Tool**: Alembic for schema migrations
- **Location**: `backend/open_webui/migrations/`
- **Versioning**: Timestamp-based migration files

### RAG Architecture

The RAG (Retrieval Augmented Generation) system is a core feature:

1. **Document Ingestion**: Upload and process various file types
2. **Embedding**: Use sentence transformers for vector embeddings
3. **Vector Storage**: Support for multiple vector databases
4. **Retrieval**: Query-based document retrieval
5. **Reranking**: Optional reranking for better results
6. **Integration**: Seamless integration with chat via `#` command

### Real-time Communication

- **WebSocket**: Socket.IO for real-time features
- **Location**: `backend/open_webui/socket/`
- **Use Cases**: Live chat updates, streaming responses, notifications

---

## Code Conventions & Standards

### Frontend Conventions

#### TypeScript
- **Strict Mode**: Enabled in tsconfig.json
- **Type Definitions**: Define interfaces in `src/lib/types/`
- **Naming**:
  - Interfaces: PascalCase (e.g., `UserModel`)
  - Variables/functions: camelCase
  - Constants: UPPER_SNAKE_CASE
  - Components: PascalCase filenames

#### Svelte
- **Component Structure**:
  ```svelte
  <script lang="ts">
    // Imports
    // Props
    // State
    // Reactive statements
    // Functions
    // Lifecycle hooks
  </script>

  <!-- Template -->

  <style>
    /* Scoped styles */
  </style>
  ```
- **File Naming**: PascalCase for components (e.g., `ChatBubble.svelte`)
- **Route Files**: lowercase with special prefixes (+page, +layout, +server)

#### Styling
- **Utility-First**: Use Tailwind CSS utilities
- **Custom Styles**: Only when necessary, scoped to component
- **Theme Support**: Use CSS variables for theming
- **Responsive**: Mobile-first approach

#### ESLint Rules
- Based on `eslint:recommended`
- TypeScript plugin enabled
- Svelte plugin enabled
- Cypress plugin for test files
- Prettier integration (no style conflicts)

### Backend Conventions

#### Python Style
- **Formatter**: Black (line length: 100)
- **Style Guide**: PEP 8 compliant
- **Imports**: Grouped (standard library, third-party, local)
- **Type Hints**: Use where appropriate (not enforced everywhere)

#### FastAPI
- **Route Naming**: RESTful conventions
  - `GET /api/v1/resource` - List
  - `GET /api/v1/resource/{id}` - Get one
  - `POST /api/v1/resource` - Create
  - `PUT /api/v1/resource/{id}` - Update (full)
  - `PATCH /api/v1/resource/{id}` - Update (partial)
  - `DELETE /api/v1/resource/{id}` - Delete
- **Response Models**: Always define Pydantic models
- **Error Handling**: Use HTTPException with appropriate status codes
- **Documentation**: Docstrings for all public functions

#### Database
- **Model Naming**: Singular (e.g., `User` not `Users`)
- **Table Naming**: Lowercase singular (e.g., `user`)
- **Field Naming**: snake_case
- **Timestamps**: Include `created_at`, `updated_at` where relevant
- **Soft Deletes**: Consider for user data

### Git Conventions

#### Commit Messages
- **Format**: `type: description`
- **Types**: feat, fix, docs, style, refactor, test, chore
- **Examples**:
  - `feat: add support for custom embedding models`
  - `fix: resolve chat history pagination issue`
  - `docs: update installation instructions`

#### Branch Naming
- **Feature**: `feature/description`
- **Bugfix**: `fix/description`
- **Hotfix**: `hotfix/description`
- **Development**: `dev` (main development branch)

#### Pull Requests
- Open discussion before large PRs
- Include tests for new features
- Update documentation
- Clear, descriptive commit messages
- Complete in timely manner (project moves fast)

---

## Development Workflow

### Available npm Scripts

```bash
# Development
npm run dev              # Start dev server on default port with Pyodide
npm run dev:5050         # Start dev server on port 5050

# Building
npm run build            # Production build
npm run preview          # Preview production build

# Code Quality
npm run check            # TypeScript type checking
npm run check:watch      # Watch mode type checking
npm run lint             # Lint all (frontend + types + backend)
npm run lint:frontend    # ESLint with auto-fix
npm run lint:types       # TypeScript checking
npm run lint:backend     # Pylint for Python

# Formatting
npm run format           # Format all files with Prettier
npm run format:backend   # Format Python with Black

# Testing
npm run test:frontend    # Run Vitest tests
npm run cy:open          # Open Cypress for e2e tests

# i18n
npm run i18n:parse       # Extract translation keys

# Other
npm run pyodide:fetch    # Download Pyodide distribution
```

### Backend Scripts

```bash
# Development server
./backend/dev.sh         # Unix/Linux/Mac
./backend/start_windows.bat  # Windows

# Database migrations
cd backend
alembic revision --autogenerate -m "description"
alembic upgrade head
alembic downgrade -1
```

### Typical Development Flow

#### Adding a New Feature

1. **Backend First**:
   ```bash
   # Create model (if needed)
   # backend/open_webui/models/my_feature.py

   # Create router
   # backend/open_webui/routers/my_feature.py

   # Register router in main.py

   # Create migration (if DB changes)
   alembic revision --autogenerate -m "add my_feature table"
   alembic upgrade head
   ```

2. **Frontend API Client**:
   ```bash
   # Create API module
   # src/lib/apis/my-feature/index.ts

   # Export from main API index
   # src/lib/apis/index.ts
   ```

3. **Frontend UI**:
   ```bash
   # Create components
   # src/lib/components/my-feature/

   # Create routes (if needed)
   # src/routes/(app)/my-feature/

   # Add i18n strings
   # src/lib/i18n/locales/en-US/translation.json
   ```

4. **Testing**:
   ```bash
   # Write backend tests
   # backend/open_webui/test/test_my_feature.py

   # Write frontend tests
   # Write Cypress e2e test if applicable
   ```

5. **Documentation**:
   - Update relevant docs
   - Add JSDoc/docstrings
   - Update CHANGELOG if applicable

#### Fixing a Bug

1. **Reproduce**: Create a minimal reproduction
2. **Write Test**: Failing test that demonstrates the bug
3. **Fix**: Implement the fix
4. **Verify**: Ensure test passes
5. **Check**: Run linters and other tests
6. **Document**: Update comments if logic is complex

---

## Testing

### Frontend Testing

#### Vitest (Unit/Integration)
```bash
npm run test:frontend

# Watch mode
npm run test:frontend -- --watch

# Coverage
npm run test:frontend -- --coverage
```

Test files: `*.test.ts` or `*.spec.ts`

#### Cypress (E2E)
```bash
npm run cy:open  # Interactive mode

# Headless (in CI)
npx cypress run
```

Test files: `cypress/e2e/**/*.cy.ts`

### Backend Testing

#### pytest
```bash
cd backend
pytest

# With coverage
pytest --cov=open_webui

# Specific test
pytest open_webui/test/test_auths.py

# Verbose
pytest -v
```

### Docker Testing

The project includes Docker-based integration tests:
```bash
docker-compose -f docker-compose.playwright.yaml up
```

---

## Key Concepts

### Authentication & Authorization

#### Authentication Methods
- **Local**: Email/password with JWT
- **OAuth**: Google, Microsoft, LDAP
- **API Keys**: For programmatic access

#### User Roles
- **pending**: Newly registered, no access
- **user**: Standard user access
- **admin**: Full administrative access

#### Permission Model
- Role-based access control (RBAC)
- Group-based permissions
- Model-level access control

### Chat System

#### Chat Structure
- **Chats**: Conversation containers
- **Messages**: Individual messages with role (user/assistant/system)
- **Context**: Message history management
- **Metadata**: Tags, folders, sharing

#### Multi-Model Chats
- Query multiple models simultaneously
- Compare responses
- Model-specific parameters

### Function Calling

#### Native Python Functions
- Define functions in workspace
- Auto-discovery and registration
- Type hints for parameters
- Execution sandbox (RestrictedPython)

#### Tool Integration
- External tool calling
- API integrations
- Custom pipelines

### Knowledge Base / RAG

#### Document Processing
- Upload various formats (PDF, DOCX, TXT, etc.)
- Chunking strategies
- Metadata extraction

#### Vector Storage
- Multiple backend support
- Configurable embedding models
- Efficient similarity search

#### Query Enhancement
- Query rewriting
- Context selection
- Reranking

### Pipelines

Extensibility framework for custom logic:
- **Filter Pipelines**: Pre/post-process messages
- **Action Pipelines**: Custom actions
- **Integration Pipelines**: External service integration

Repository: https://github.com/open-webui/pipelines

---

## Common Tasks

### Adding a New Language

1. Create language directory:
   ```bash
   mkdir -p src/lib/i18n/locales/es-ES
   ```

2. Copy English translations:
   ```bash
   cp src/lib/i18n/locales/en-US/*.json src/lib/i18n/locales/es-ES/
   ```

3. Translate strings in JSON files

4. Register language:
   ```json
   // src/lib/i18n/locales/languages.json
   {
     "es-ES": "Español (España)"
   }
   ```

### Adding a New Database Field

1. Update SQLAlchemy model:
   ```python
   # backend/open_webui/models/users.py
   class User(Base):
       # ... existing fields
       new_field = Column(String, nullable=True)
   ```

2. Update Pydantic model:
   ```python
   class UserModel(BaseModel):
       # ... existing fields
       new_field: Optional[str] = None
   ```

3. Create migration:
   ```bash
   cd backend
   alembic revision --autogenerate -m "add new_field to user"
   alembic upgrade head
   ```

4. Update frontend types:
   ```typescript
   // src/lib/types/user.ts
   export interface User {
     // ... existing fields
     new_field?: string;
   }
   ```

### Adding a New API Endpoint

1. **Backend** (`backend/open_webui/routers/my_router.py`):
   ```python
   from fastapi import APIRouter, Depends
   from open_webui.models.users import Users

   router = APIRouter()

   @router.get("/api/v1/myendpoint")
   async def get_my_data(user=Depends(Users.get_current_user)):
       return {"data": "value"}
   ```

2. **Register router** (`backend/open_webui/main.py`):
   ```python
   from open_webui.routers import my_router

   app.include_router(my_router.router, tags=["my_feature"])
   ```

3. **Frontend API** (`src/lib/apis/my-endpoint/index.ts`):
   ```typescript
   export const getMyData = async (token: string) => {
     const res = await fetch('/api/v1/myendpoint', {
       headers: {
         'Authorization': `Bearer ${token}`
       }
     });
     return res.json();
   };
   ```

### Debugging Tips

#### Frontend
- Use browser DevTools
- Check Network tab for API calls
- Use Svelte DevTools extension
- Check console for errors
- `console.log()` or `$inspect()` in Svelte

#### Backend
- Use FastAPI's automatic docs at `/docs`
- Check backend logs
- Use `log.info()` / `log.error()` from `open_webui.utils.logger`
- Use debugger (pdb) for complex issues
- Check database queries with SQLAlchemy echo

#### Docker
- View logs: `docker logs open-webui`
- Access container: `docker exec -it open-webui sh`
- Check volumes: `docker volume ls`
- Inspect network: `docker network inspect`

---

## Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Find process using port 8080
lsof -i :8080  # Unix/Mac
netstat -ano | findstr :8080  # Windows

# Kill process or change port
npm run dev:5050
```

#### Database Migration Issues
```bash
# Check current version
cd backend
alembic current

# Reset to head (caution: may lose data)
alembic downgrade base
alembic upgrade head

# Stamp current version without running migrations
alembic stamp head
```

#### Pyodide Download Issues
```bash
# Manually fetch Pyodide
npm run pyodide:fetch

# Or download and place in static/pyodide/
```

#### Docker Volume Permission Issues
```bash
# Fix volume permissions
docker run --rm -v open-webui:/data alpine chown -R 1000:1000 /data
```

#### Frontend Build Fails
```bash
# Clear cache and reinstall
rm -rf node_modules .svelte-kit build
npm ci
npm run build
```

#### Backend Won't Start
```bash
# Check Python version
python --version  # Should be 3.11.x

# Reinstall dependencies
pip install --upgrade pip
pip install -r requirements.txt --force-reinstall
```

### Getting Help

1. **Documentation**: https://docs.openwebui.com/
2. **GitHub Issues**: https://github.com/open-webui/open-webui/issues
3. **Discord Community**: https://discord.gg/5rJgQTnV4s
4. **Discussions**: https://github.com/open-webui/open-webui/discussions

---

## Best Practices for AI Assistants

### When Making Changes

1. **Understand Context**: Read related code before making changes
2. **Maintain Consistency**: Follow existing patterns in the codebase
3. **Test Changes**: Ensure changes don't break existing functionality
4. **Update Types**: Keep TypeScript types and Pydantic models in sync
5. **Consider i18n**: If adding UI text, use translation keys
6. **Document**: Add comments for complex logic
7. **Security**: Be mindful of XSS, injection, auth bypass vulnerabilities

### Code Review Checklist

- [ ] Follows coding conventions
- [ ] Types/schemas are properly defined
- [ ] Error handling is appropriate
- [ ] Security considerations addressed
- [ ] Performance implications considered
- [ ] Backwards compatibility maintained
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] i18n strings added if applicable
- [ ] No console.log() in production code
- [ ] Database migrations included if schema changes

### Anti-Patterns to Avoid

- **Don't** bypass authentication/authorization checks
- **Don't** store sensitive data in frontend state
- **Don't** use `any` type in TypeScript unless absolutely necessary
- **Don't** create SQL queries with string concatenation (use ORM)
- **Don't** commit `.env` files or secrets
- **Don't** make breaking API changes without versioning
- **Don't** use blocking operations in async functions
- **Don't** ignore TypeScript errors (fix them)
- **Don't** duplicate code (DRY principle)

---

## Additional Resources

### External Documentation
- **SvelteKit**: https://kit.svelte.dev/docs
- **FastAPI**: https://fastapi.tiangolo.com/
- **SQLAlchemy**: https://docs.sqlalchemy.org/
- **Tailwind CSS**: https://tailwindcss.com/docs
- **Vite**: https://vitejs.dev/guide/

### Related Projects
- **Pipelines**: https://github.com/open-webui/pipelines
- **Ollama**: https://ollama.com/
- **Community Models**: https://openwebui.com/

### Learning Resources
- Docker: https://docs.docker.com/get-started/
- Kubernetes: https://kubernetes.io/docs/tutorials/
- RAG Concepts: LangChain documentation

---

## Changelog

This document will be updated as the codebase evolves. Major architectural changes, new patterns, or significant feature additions should be reflected here.

**Last Updated**: 2025-11-13
**Version**: Based on Open WebUI v0.6.5
**Maintainer**: Auto-generated for AI assistants

---

**End of Document**
