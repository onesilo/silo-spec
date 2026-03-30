# Trip Planning Example

A `.silo` package for a two-week Italy trip (Rome → Florence → Amalfi Coast).

**Mode:** `augmented` — the recipient's personal context (dietary restrictions, preferences) enriches answers, but trip details are not fabricated.

**Demonstrates:**
- Facts (dates, budget, transport, dining philosophy)
- Decisions with reasoning (Ravello over Positano, Airbnb over hotels, skipping Venice)
- Narrative blocks (per-city itineraries, budget breakdown, restaurant research)
- Insights (travel style patterns derived from decisions)
- Open items (unresolved bookings and decisions)
- Entities (accommodations, restaurants, people)
- Relationships between entities
- Topics for hierarchical organization
- Config with system instructions, welcome message, and suggested prompts

**To package as a .silo file:**

```bash
cd examples/trip-planning
zip -r ../../trip-planning.silo manifest.json silo.json refs/
```
