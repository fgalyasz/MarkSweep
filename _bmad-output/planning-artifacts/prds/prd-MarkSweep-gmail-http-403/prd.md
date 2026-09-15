---
title: MarkSweep Gmail HTTP 403
status: final
created: 2026-09-15
updated: 2026-09-15
parent_issue: https://github.com/fgalyasz/MarkSweep/issues/14
---

# PRD: MarkSweep Gmail HTTP 403

Hobby/solo. One user-visible goal: after Google sign-in, a 403 shows why (usually Gmail API disabled), not only `Gmail HTTP 403.`

## 1. Vision

OAuth can succeed while Gmail API calls fail. The Connect screen must say what to do.

## 2. User journeys

- **UJ-1.** Sign-in returns to MarkSweep. Gmail API is off. The red line tells Ferenc to enable Gmail API and Connect again.

## 3. Features

#### FR-1: Surface Google error text

Failed HTTP responses parse `error.message` / `error_description`. Status 403 with "has not been used" maps to an enable-API sentence.

**Consequences:**
- Empty bodies still show `Gmail HTTP 403.`
- Other 403s include Google's message.

## 4. Non-goals

- Enabling the API from the app.
- Changing OAuth scopes.

## 5. Success metrics

- **SM-C1**: Tests cover disabled-API copy and JSON parse; `swift test` green.
