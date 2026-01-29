---
name: repo-map
description: Generates a hierarchical repository map showing file structure, key symbols (classes, functions, exports), and dependencies. Use when exploring a new codebase, planning refactoring, understanding architecture, or when user says "map the repo", "show structure", or "what's in this codebase".
allowed-tools: Read, Grep, Glob, Bash, tree
---

# Hierarchical Repository Mapper

Generate a token-efficient map of the repository that captures structure, key symbols, and relationships without reading every file in full.

## When to Use

- Starting work on an unfamiliar codebase
- Before making cross-file changes
- Understanding how modules connect
- Answering "where is X defined?" questions
- Reducing context window usage on large projects

## Mapping Process

### Step 0 : run `tree` if available

### Step 1: Discover Project Type

Identify the project by checking for config files:

```bash
# Check for common project markers
ls -la package.json pyproject.toml Cargo.toml go.mod pom.xml build.gradle Makefile CMakeLists.txt DESCRIPTION NAMESPACE renv.lock 2>/dev/null
```

**R Package Detection:**
```bash
# If DESCRIPTION exists, it's an R package
if [ -f DESCRIPTION ]; then
  grep -E "^Package:|^Version:|^Title:" DESCRIPTION
  # Check for Shiny
  grep -q "shiny" DESCRIPTION && echo "Type: Shiny app"
fi
```

### Step 2: Build Directory Tree

Generate a filtered directory tree (exclude noise):

```bash
# Tree with exclusions for common noise directories
find . -type f \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -not -path '*/dist/*' \
  -not -path '*/build/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*/venv/*' \
  -not -path '*/.venv/*' \
  -not -path '*/coverage/*' \
  -not -path '*/renv/library/*' \
  -not -path '*/man/*' \
  -not -name '*.lock' \
  -not -name 'package-lock.json' \
  -not -name '*.Rd' \
  | head -200
```

### Step 3: Extract Key Symbols

For each significant source file, extract definitions without reading the full file.

**JavaScript/TypeScript:**
```bash
# Find exports and key definitions
grep -n "^export\|^class\|^function\|^const.*=.*=>\|^interface\|^type " src/**/*.{js,ts,tsx} 2>/dev/null | head -100
```

**Python:**
```bash
# Find class and function definitions
grep -n "^class\|^def\|^async def" **/*.py 2>/dev/null | head -100
```

**Go:**
```bash
# Find type and func definitions
grep -n "^type\|^func" **/*.go 2>/dev/null | head -100
```

**Rust:**
```bash
# Find pub items
grep -n "^pub fn\|^pub struct\|^pub enum\|^pub trait\|^impl" **/*.rs 2>/dev/null | head -100
```

**R (Package Structure):**
```bash
# Function definitions in R/
grep -rn "^[a-zA-Z_][a-zA-Z0-9_.]* *<- *function" R/ --include="*.R" 2>/dev/null | head -50

# S3 methods (name.class pattern)
grep -rn "^[a-zA-Z_]*\.[a-zA-Z_]* *<- *function" R/ --include="*.R" 2>/dev/null | head -20

# R6 and S4 classes
grep -rn "R6Class\|setClass\|setRefClass\|setGeneric" R/ --include="*.R" 2>/dev/null | head -20

# Exported functions from NAMESPACE
grep "^export\|^S3method" NAMESPACE 2>/dev/null | head -30
```

**R (Shiny Apps):**
```bash
# Shiny modules (UI + Server pairs)
grep -rn "Server *<- *function\|UI *<- *function\|_ui *<- *function\|_server *<- *function" R/ --include="*.R" 2>/dev/null

# Module patterns (NS, moduleServer)
grep -rn "moduleServer\|NS(" R/ --include="*.R" 2>/dev/null | head -20

# App entry points
grep -rn "shinyApp\|runApp\|run_app" R/ --include="*.R" 2>/dev/null
```

### Step 4: Identify Entry Points

Find main entry points and key configuration:

```bash
# Common entry points
cat package.json 2>/dev/null | grep -A5 '"main"\|"scripts"' | head -20
cat pyproject.toml 2>/dev/null | grep -A3 '\[tool.poetry.scripts\]' | head -10
grep -l "^func main\|^def main\|if __name__" **/*.{go,py} 2>/dev/null | head -5
```

**R Package Entry Points:**
```bash
# Package metadata
cat DESCRIPTION 2>/dev/null | grep -E "^Package:|^Version:|^Imports:|^Depends:|^Suggests:"

# Shiny app entry (golem/rhino pattern)
grep -l "run_app\|shinyApp" R/*.R 2>/dev/null

# Data files
ls -la data/ inst/extdata/ 2>/dev/null | head -10
```

### Step 5: Map Dependencies

Identify how files connect:

```bash
# Import analysis (JS/TS)
grep -rh "^import.*from\|^require(" src/ 2>/dev/null | sort | uniq -c | sort -rn | head -20

# Import analysis (Python)
grep -rh "^from.*import\|^import " **/*.py 2>/dev/null | sort | uniq -c | sort -rn | head -20
```

**R Package Dependencies:**
```bash
# roxygen2 @importFrom tags (internal dependency tracking)
grep -rh "^#' *@importFrom\|^#' *@import " R/ 2>/dev/null | sort | uniq -c | sort -rn | head -15

# Package dependencies from DESCRIPTION
grep -A20 "^Imports:" DESCRIPTION 2>/dev/null | head -15

# Internal function calls between files (box:: style)
grep -rh "box::use\|source(" R/ 2>/dev/null | head -10
```

## Output Format

Present the map in this structure:

```
## Repository Map: [project-name]

### Project Type
[Language/Framework] | [Build Tool] | [Test Framework]

### Directory Structure
```
project/
├── src/                    # Source code
│   ├── components/         # UI components (React)
│   ├── services/           # Business logic
│   └── utils/              # Shared utilities
├── tests/                  # Test suites
└── config/                 # Configuration
```

### Key Symbols

#### src/services/auth.ts
- `class AuthService` (line 15) - Handles authentication flow
- `function validateToken()` (line 42) - JWT validation
- `export const AUTH_CONFIG` (line 5) - Configuration constants

#### src/components/Dashboard.tsx
- `function Dashboard()` (line 8) - Main dashboard component
- `function useMetrics()` (line 45) - Custom hook for metrics

### Entry Points
- `src/main.ts:12` - Application bootstrap
- `src/server.ts:8` - HTTP server initialization

### Dependency Graph (Top Importers)
- `src/services/api.ts` - imported by 12 files
- `src/utils/helpers.ts` - imported by 8 files
- `src/types/index.ts` - imported by 15 files

### Architecture Notes
[Brief observations about patterns, potential issues, or notable design decisions]
```

## Token Budget Guidelines

| Repo Size | Max Map Tokens | Strategy |
|-----------|----------------|----------|
| < 50 files | ~500 tokens | Full symbol listing |
| 50-200 files | ~1000 tokens | Key files + top symbols |
| 200+ files | ~2000 tokens | Directory tree + entry points + dependency graph |

## Refresh Triggers

Regenerate the map when:
- User asks about unfamiliar parts of the codebase
- Making changes that span multiple modules
- Starting a new task in a different area
- Map is more than ~20 conversation turns old

## Integration with Other Strategies

This map complements other context strategies:
- Use the map for **navigation** (where is X?)
- Use **grep/search** for specific content lookup
- Use **full file reads** only for files you're actively modifying

## Example: Mapping a Monorepo

For monorepos, show package relationships:

```
monorepo/
├── packages/
│   ├── core/           # @myapp/core - shared business logic
│   │   └── depends on: (none)
│   ├── ui/             # @myapp/ui - component library
│   │   └── depends on: @myapp/core
│   └── api/            # @myapp/api - backend service
│       └── depends on: @myapp/core
└── apps/
    └── web/            # Main application
        └── depends on: @myapp/ui, @myapp/api
```

## Example: Mapping an R Package (Shiny App)

For R packages with Shiny modules (golem/rhino pattern):

```
## Repository Map: myshinyapp

**Type:** R Package | Shiny | renv | testthat | golem

### Package Metadata
- Package: myshinyapp
- Version: 0.1.0
- Imports: shiny, bslib, DBI, dplyr, R6

### Exports (NAMESPACE)
- export(run_app)
- export(mod_dashboard_ui, mod_dashboard_server)
- export(mod_upload_ui, mod_upload_server)
- S3method(print, db_connection)

### Directory Structure
myshinyapp/
├── DESCRIPTION              # Package metadata & dependencies
├── NAMESPACE                # Exports (roxygen2 generated)
├── R/
│   ├── app_config.R         # App configuration
│   ├── app_server.R         # Main server function
│   ├── app_ui.R             # Main UI function
│   ├── mod_dashboard.R      # Dashboard module (UI + Server)
│   ├── mod_upload.R         # File upload module
│   ├── fct_database.R       # Database helper functions
│   ├── fct_processing.R     # Data processing functions
│   ├── utils_helpers.R      # Utility functions
│   └── run_app.R            # App launcher (entry point)
├── inst/
│   ├── app/www/             # Static assets (CSS, JS, images)
│   └── extdata/             # Sample data files
├── tests/testthat/          # Unit tests
├── data-raw/                # Scripts to generate package data
└── renv.lock                # Dependency lockfile

### Key Functions
- `R/run_app.R:8` → run_app(options) - App entry point
- `R/app_server.R:12` → app_server(input, output, session)
- `R/app_ui.R:5` → app_ui(request)
- `R/fct_database.R:15` → connect_db(config) - DB connection
- `R/fct_database.R:42` → query_data(conn, sql)

### Shiny Modules
| File | UI Function | Server Function | Purpose |
|------|-------------|-----------------|---------|
| mod_dashboard.R | mod_dashboard_ui | mod_dashboard_server | Main metrics view |
| mod_upload.R | mod_upload_ui | mod_upload_server | File upload handler |

### Package Dependencies (@importFrom usage)
- shiny: NS, moduleServer, reactive (15 uses)
- dplyr: mutate, filter, select, %>% (12 uses)
- DBI: dbConnect, dbGetQuery (8 uses)
- bslib: page_sidebar, card (6 uses)

### Architecture Notes
- Follows golem structure with mod_* naming convention
- Uses renv for reproducible dependencies
- Database connections managed via R6 class in fct_database.R
- UI theming via bslib (Bootstrap 5)
```
