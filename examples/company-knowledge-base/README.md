# Company Knowledge Base Example

A `.silo` package for an internal company knowledge base (Meridian Labs — a fictional hardware engineering platform).

**Mode:** `container` — answers must come exclusively from silo content. No fabrication of company details.

**Demonstrates:**
- Facts (company info, headcount, funding, ARR, runway)
- Decisions with reasoning (PLG strategy, build vs acquire, pricing model)
- Narrative blocks (vision, mission, product, GTM, competitive landscape, team, messaging)
- Insights (product strategy patterns)
- Open items (partnerships, compliance decisions)
- Entities (company, team members, investors, competitors)
- Relationships (founded, works_at, invested_in, competes_with)
- Subject entity (`subject_entity_id` points to the company entity)
- App-specific extensions (`app.onesilo.access_roles` for role-based access)
- Config with strict container mode instructions and citation requirement

**To package as a .silo file:**

```bash
cd examples/company-knowledge-base
zip -r ../../company-knowledge-base.silo manifest.json silo.json refs/
```
