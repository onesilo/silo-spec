# MemoryStore Interface Specification v0.1.0

## Status

Draft — v0.1.0

## Overview

The MemoryStore interface is the standard memory abstraction for One Silo
agents (Agent Smith, SILO-120). It defines the operations an agent uses to
remember, recall, and forget knowledge in a silo, independent of *where*
that silo lives — the cloud control plane, a self-hosted node, a gateway
relay, or a local file.

The interface was extracted from the Buzz agent (`onesilo-buzz`), where four
interchangeable backends implement it. This document promotes that shape to
a portable contract so "agents have memory" means the same thing in every
SDK and every deployment placement. The contract is invariant; placement is
policy.

The interface is deliberately smaller than the `.silo` file format: a
MemoryStore holds and answers over memories; the `.silo` format (see
`v0.1.1.md`) is how a silo's contents travel between systems. A conforming
store SHOULD be exportable to a `.silo` package, but this specification does
not require it.

## Terminology

The key words "MUST", "MUST NOT", "SHOULD", "SHOULD NOT", and "MAY" in this
document are to be interpreted as described in
[RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

- **Store** — an implementation of this interface bound to one or more
  silos the caller has been granted.
- **Memory** — an atomic unit of knowledge (see the `.silo` format's memory
  kinds: fact, decision, narrative, insight, open item, custom).
- **Grant** — the owner-controlled permission that scopes what a store may
  read or write. Grants are managed in the owner's dashboard, never by the
  agent.

## Design rules

1. **Governance is server-side.** A store implementation MUST NOT make
   authorization decisions locally. Write refusals, confirmation demands,
   and scope come from the backing surface (control plane, node) per
   request.
2. **Honest write outcomes.** A write is not always stored immediately.
   Implementations MUST surface the true outcome (see `RememberOutcome`)
   and MUST NOT auto-confirm a write the backing surface flagged for owner
   confirmation.
3. **Capability detection over feature flags.** Optional operations are
   detected by presence (`store.ask != nil`), so wrappers that relocate
   compute keep detection accurate by forwarding only the operations their
   inner store provides.
4. **Provenance is append-anchored.** When an implementation attaches
   provenance to memory content, it MUST do so in a way that user-supplied
   text cannot spoof (e.g. a trailer parsed only at end-of-string).

## Required operations

Conforming stores MUST provide:

| Operation | Signature (language-neutral) | Semantics |
|---|---|---|
| `remember` | `(silo_id, statement, kind?, metadata?) → RememberOutcome` | Persist one memory. MUST return the honest outcome. |
| `recall` | `(silo_id, query, limit?) → Memory[]` | Retrieve memories relevant to the query. |
| `forget` | `(silo_id, memory_id) → void` | Remove one memory. MUST fail (not silently no-op) when the grant does not permit writes. |
| `recent` | `(silo_id, limit?) → Memory[]` | Most recently written memories, newest first. |

## Optional operations

Stores MAY provide; callers MUST feature-detect before use:

| Operation | Signature | Semantics |
|---|---|---|
| `ask` | `(silo_id, question) → string` | A grounded answer composed over the silo's contents (server-side compute). |
| `overview` | `(silo_id) → SiloOverview` | Title, counts, and welcome/config summary. |
| `rememberTranscript` | `(silo_id, turns[], metadata?) → RememberOutcome` | Submit raw conversational turns for server-side distillation instead of client-side extraction. |
| `init` | `() → void` | Startup scope discovery (e.g. `get_scope`); a store MUST warn, not fail, when a configured silo is out of scope. |

## RememberOutcome

The result of any write operation. One of:

- `stored` — durably written.
- `queued` — accepted and buffered (e.g. the backing node is temporarily
  unreachable); the implementation retries and MUST NOT silently degrade to
  a less private path.
- `needs_confirmation` — the backing surface requires the silo owner to
  approve (typically a memory-replacing write). The agent MUST surface this
  state and MUST NOT confirm on the owner's behalf; confirmation happens in
  the owner's dashboard.

## Naming alignment

Where a store is backed by the One Silo control plane over MCP, operations
map 1:1 onto the MCP tool vocabulary: `silo_remember`, `silo_recall`,
`silo_forget`, `silo_ask`, `get_scope`. Implementations SHOULD keep this
mapping so behavior documented for one surface holds for the other.

## Decorators

Implementations SHOULD be composable by wrapping. The canonical example is
distillation placement: a wrapper that intercepts `rememberTranscript`,
distills locally (on the owner's node), and forwards distilled memories to
the inner store's `remember` — moving compute without changing the
interface. Wrappers MUST forward optional-operation presence accurately
(rule 3).

## Reference implementations

- `onesilo-buzz` `src/silo/types.ts` — the interface; `mcp-store.ts`
  (cloud MCP, OAuth), gateway relay (node-held credential), node memory API
  (`X-Silo-Node-Key`), and local file backends.
- `onesilo-node` Memory API — the node-local backing surface.

## Versioning Rules

Same policy as the `.silo` format: additive-only evolution. New optional
operations and new `RememberOutcome` values MAY be added in minor versions;
callers MUST treat unknown outcome values as `queued` (the conservative
reading: not confirmed stored, not lost). Removing or changing required
operations requires a major version.
