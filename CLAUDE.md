# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Development (Docker)
docker-compose up              # Start app + PostgreSQL

# Development (local — Ruby 3.4.7)
bin/setup                      # Install deps, create/migrate DB, start server
bin/setup --skip-server        # Setup without starting server
bin/setup --reset              # Full DB reset
bin/dev                        # Start server after setup

# Database
bin/rails db:migrate
bin/rails db:prepare           # create + migrate

# Tests
bin/rails test                 # All tests
bin/rails test test/path/to/test.rb  # Single file

# Linting & Security
bin/rubocop                    # Style
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit

# Full CI pipeline (runs all of the above in order)
bin/ci
```

## Architecture

Rails 8.1 **API-only** app (no views) for a psychology clinic management system. All responses are JSON with the envelope `{ success: true/false, ... }`.

### Domain

- **Profile** — core entity. Has three roles: `admin`, `therapist`, `patient`. Therapists have many patient Profiles. Carries personal data (CPF, CRP, etc.) and a profile photo (Active Storage).
- **User** — Devise + JWT authentication, one-to-one with Profile.
- **Service** — a therapy session/appointment, belongs to therapist and patient Profiles.
- **MedicalRecord** — session notes (belongs to Service, has file attachments).
- **Payment** — billing for a Service (computed status: paid/unpaid/overdue, has file attachments).
- **Anamnese** — patient intake/history (JSONB data), belongs to therapist + patient Profiles.

### Authorization

- `User.current` is a thread-local set in `ApplicationController#set_current_user`.
- Models expose `.allowed` (scope for index queries) and `#allowed?` (for show/update/destroy) based on role. Therapists see only their own data; admins see everything.

### Patterns

**Models:**
- Each model has a `show` instance method that returns a hash of attributes + expanded associations (used by controllers instead of serializers).
- Filtering class methods (`by_status`, `by_name`, `by_date_start`, etc.) accept `nil` and return `all` when blank.
- Enums are used extensively (role, gender, payment_method, service_type, etc.).

**Controllers:**
- `before_action :set_*` — finds record or renders 404 via `render_not_found(Model)`.
- `before_action :check_permissions` — role/ownership checks, renders 403 via `render_not_allowed`.
- `filter_params` — handles nested query filters (e.g. `params[:profiles][:role]`).
- `order_by` — translates string param (e.g. `"name_asc"`) to ActiveRecord hash.
- Strong params end with `.to_h.symbolize_keys`.

**File uploads:** Active Storage, local disk storage. Profile has `has_one_attached :photo`; Payment and MedicalRecord have `has_many_attached :attachments`. URLs are generated with `rails_blob_url` — host is set per-request in `ApplicationController#set_url_options`.

**Pagination:** Kaminari, default 30/page. Pass `page` and `per_page` params.

### Key Config

- CORS allows `http://localhost:3001` (frontend dev server) — see `config/initializers/cors.rb`.
- JWT expiry: 1 day, revocation via JTI matcher.
- Background jobs: `solid_queue`. Caching: `solid_cache`.
- I18n error strings are in Portuguese.
