# Research Topic #7 — Legal/ToS For Puzzle Sources

Status: Resolved
Owner: Codex

## Research Question

What do the terms of service and licensing rules allow for fetching, caching, displaying, attributing, and redistributing puzzle content?

## Decision To Unblock

Which puzzle sources can the app safely build around without relying on prohibited scraping, unauthorized caching, or redistribution of publisher-owned puzzle content?

## Recommendation

Treat publisher-hosted web puzzles as unsafe for automated fetching/caching unless the publisher provides an explicit API/license or written permission. For Phase 1, make local `.puz`/`.ipuz` import and explicitly licensed indie/static feeds the safe content foundation. Universal, LA Times, and Guardian should not be treated as launch sources until source-specific permission or a clearly licensed distribution channel is confirmed.

This is not legal advice. Before shipping any source downloader, get human legal/business review for that source's current terms, robots.txt, endpoint behavior, cache plan, and attribution.

## High-Level Rule

Free-to-play does not mean free-to-republish. A crossword can be publicly playable in a browser while still being protected by copyright, terms of service, anti-scraping clauses, cache restrictions, and syndication contracts.

The app should distinguish:

- **User import:** user supplies a file they already have. Safest app-owned behavior.
- **Explicit licensed feed:** source grants permission to fetch/cache/display puzzles in an app. Safe if terms are followed.
- **Public web page scraping:** app extracts puzzle content from a website. High risk.
- **Aggregator scraping:** app fetches from a third party that may not own rights to redistribute. High risk.

## Source Assessment

| Source | Current Finding | Risk | Decision |
|--------|-----------------|------|----------|
| Local `.puz` / `.ipuz` import | User provides the file; app stores local copy and progress. Rights depend on user's source, but the app is not redistributing. | Low | Use in Phase 1. |
| Indie/static puzzle feeds | Safe only when constructor/site grants explicit download/cache/display rights, ideally with license and attribution terms. | Low/medium | Good Phase 1 path if licenses are explicit. |
| Universal Crossword / Andrews McMeel | Universal is a syndication product. AMU terms reserve rights, limit use to personal/noncommercial site viewing, and prohibit storing/copying/making site materials available without permission. | High | Do not scrape. Contact AMU for syndication/API/license. |
| LA Times Crossword | LA Times games are free to play, but LA Times terms restrict content to personal/noncommercial online use and prohibit archiving, caching, scraping, copying, distributing, or incorporating content in a database without permission. | High | Do not scrape/cache. Seek permission/license before source integration. |
| Guardian Crossword | Guardian site terms allow personal noncommercial use only and expressly prohibit scraping/crawling/extracting Guardian content without approval. Guardian Open Platform exists, but its terms/API scope must be confirmed for crosswords and registered-key use. | High | Do not scrape. Only consider an official API/license path after review. |
| Wordplays or similar aggregators | No reliable permission source found, and aggregators generally cannot grant rights to underlying publisher puzzles unless explicitly licensed. | High | Do not use as a source of puzzle content. |
| NYT | Subscription/premium source; `.puz` downloads discontinued. Third-party app access would require user credentials and terms review. | High | Post-MVP only, if ever. |

## Publisher Notes

### Universal / Andrews McMeel

Universal Crossword is presented by Andrews McMeel Syndication as a syndication product for audiences across print/digital/mobile. AMU's general terms say site materials are protected, no ownership rights are assigned, site use is limited to personal/noncommercial purposes unless specific permission is granted, and displaying/storing/copying/making content available without written permission is prohibited.

Practical implication: Universal is not a scrape candidate. The right path is a syndication conversation or explicit developer/license agreement.

Confidence: High for "do not scrape"; medium for exact licensing route because a separate syndication agreement may exist outside public terms.

### LA Times

LA Times confirms the Daily Crossword is free to play on the web. Their terms, however, restrict content use and prohibit republishing, archiving, caching, scraping, copying, distributing, or incorporating content into databases without permission.

Practical implication: the app should not fetch/cache LA Times puzzle content from the web player. "Free to play" supports linking users to the site, not importing puzzle data into a native app.

Confidence: High.

### Guardian

Guardian terms state Guardian content is for personal, noncommercial use and prohibit scraping/crawling/extracting Guardian content without written approval. Guardian robots.txt also reinforces that Guardian content is available under their terms and directs licensing inquiries to licensing contacts. The Guardian Open Platform has its own terms and API-key model, but it does not automatically grant rights to scrape the Guardian site or cache crossword content indefinitely.

Practical implication: do not parse Guardian crossword pages. If Guardian crosswords are available through an official API/package, use only that API and follow its API-key, request-limit, attribution, advertising, cache/deletion, and publication terms.

Confidence: High for "do not scrape"; medium for "API may be possible" because crossword availability and rights under Open Platform need direct verification.

### Aggregators

Aggregators can be useful for research, links, or discovery, but they are not a rights source unless their license explicitly covers redistribution of underlying puzzles. Using an aggregator to bypass publisher restrictions compounds risk because the app may violate both aggregator and publisher terms.

Practical implication: do not rely on Wordplays or similar sites for puzzle fetching.

Confidence: Medium/high.

## Safe Phase 1 Content Strategy

1. **Local import first:** support user-selected `.puz` and `.ipuz` files.
2. **Rights-cleared fixtures:** include only puzzles with explicit permission or permissive license in test/demo data.
3. **Indie feeds by permission:** maintain a registry of constructor feeds with license URLs, attribution, cache policy, and contact.
4. **Source links:** for high-risk publishers, deep-link users to official web players instead of copying puzzle content.
5. **Syndication outreach:** contact AMU/LA Times/Guardian for written permission if those sources are still desired.

## Source Registry Legal Fields

Add these fields to each source definition before implementation:

| Field | Purpose |
|-------|---------|
| `licenseStatus` | `user_import`, `explicit_permission`, `open_license`, `needs_review`, `prohibited` |
| `licenseUrl` | Public terms/license URL |
| `permissionContact` | Email/contact or agreement reference |
| `attributionRequired` | Whether source/author/copyright display is required |
| `cachePolicy` | Whether puzzle body may be cached and for how long |
| `rawPayloadRetention` | Whether raw downloaded payload may be retained |
| `commercialUseAllowed` | Whether app support/monetization affects source rights |
| `lastLegalReviewAt` | Date reviewed |
| `reviewNotes` | Human notes and unresolved risks |

## Cache Policy Recommendations

- For local imports: store puzzle body and progress locally.
- For explicit-license feeds: follow license exactly; default to caching only puzzle body and progress needed for offline play.
- For publisher web players without permission: do not cache puzzle bodies because the app should not fetch them.
- For premium/subscription content: do not cache beyond what terms explicitly allow.
- Always store attribution/copyright metadata with the puzzle.

## Attribution Rules

Every puzzle record should preserve and display:

- Title.
- Author/constructor.
- Editor if available.
- Source/publisher.
- Copyright.
- Original URL if allowed.
- License/terms reference when available.

## Implementation Guardrails

- Do not add a downloader unless the source row has `licenseStatus` of `explicit_permission`, `open_license`, or `user_import`.
- Block `needs_review` and `prohibited` sources at runtime.
- Keep scraping code out of the app until legal review clears a source.
- Add tests that source definitions without a valid license status cannot be enabled.
- Add a `SourceLegalReview` checklist to PRs that add sources.

## Open Questions

| Question | Lean | Notes |
|----------|------|-------|
| Can Guardian be used through Open Platform? | Needs direct verification | Confirm crossword content availability, package tier, cache/deletion rules, attribution, and app use. |
| Can AMU license Universal for app distribution? | Ask AMU | Likely a syndication/business arrangement, not public scraping. |
| Can LA Times license game content? | Ask LA Times | Public terms do not permit app scraping/caching. |
| Can support-tier monetization coexist with free-source licenses? | Source-specific | Some licenses prohibit commercial use; every source needs review. |
| Are indie `.puz` files safe? | Only with explicit terms | Public file availability alone is not enough. |

## Implementation Checklist

1. Add legal fields to the source registry model.
2. Mark Universal, LA Times, Guardian, Wordplays/aggregators as `needs_review` or `prohibited` until permission exists.
3. Implement local import and rights-cleared fixtures first.
4. Create a source-review template covering terms URL, robots.txt, cache policy, attribution, commercial use, and contact.
5. Require human review before enabling any network source.
6. Keep high-risk publishers as external links until explicit permission is secured.
7. Re-review terms before each release because publisher terms can change.

## Sources

Accessed April 30, 2026.

- [Andrews McMeel Universal Terms of Service](https://www.andrewsmcmeel.com/terms-of-service/)
- [Universal Crossword at Andrews McMeel Syndication](https://syndication.andrewsmcmeel.com/features/universal-crossword-universal-crossword-weekly/)
- [Andrews McMeel Syndication overview](https://www.andrewsmcmeel.com/syndication/)
- [Los Angeles Times Terms of Service](https://www.latimes.com/terms-of-service)
- [L.A. Times Daily Crossword FAQ](https://www.latimes.com/games/daily-crossword-faq)
- [Guardian terms and conditions](https://www.theguardian.com/help/terms-of-service)
- [Guardian Open Platform terms](https://www.theguardian.com/open-platform/terms-and-conditions)
- [Guardian robots.txt](https://www.theguardian.com/robots.txt)
