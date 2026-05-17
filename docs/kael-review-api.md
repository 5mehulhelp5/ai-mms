# Kael Review API

Programmatically POST an auto-approved product review.

Implementation lives at `kael_review_api.php` at the site root. Surfaced in
the admin under **Company Setting → API Summary**.

## Endpoint

```
POST <site_base_url>/kael_review_api.php
```

Production (SG): `https://www.tertiarycourses.com.sg/kael_review_api.php`

## Authentication

Header `X-Api-Key` must match the value of the `KAEL_REVIEW_API_KEY`
environment variable on the server. The current key is shown (masked) in
the admin **Company Setting → API Summary** section.

```
X-Api-Key: <secret>
```

## Request

| Header          | Value                |
|-----------------|----------------------|
| `Content-Type`  | `application/json`   |
| `X-Api-Key`     | secret (see above)   |

Body (JSON):

| Field         | Type    | Required | Notes                                                              |
|---------------|---------|----------|--------------------------------------------------------------------|
| `product_id`  | int     | yes      | Magento product `entity_id`                                        |
| `nickname`    | string  | yes      | Reviewer display name                                              |
| `title`       | string  | yes      | Review title (the site uses `"Average Rating: X.X/5"`)             |
| `detail`      | string  | yes      | Review body                                                        |
| `ratings`     | object  | yes      | `{ "<rating_id>": <stars 1-5>, ... }` — see rating IDs below       |
| `created_at`  | string  | no       | MySQL DATETIME / ISO 8601. Defaults to server `NOW()`              |
| `store_id`    | int     | no       | Magento store view id. Defaults to current store (`1` = SG)        |
| `customer_id` | int     | no       | Magento `customer_entity.entity_id`. Defaults to `null` (guest)    |

### Rating IDs

The site uses a 3-criteria review form. Each criterion is keyed by its
`rating_id` and accepts 1–5 stars:

| `rating_id` | Question                                          |
|-------------|---------------------------------------------------|
| `1`         | Do you find the course meets your expectation?    |
| `2`         | Do you find the trainer knowledgeable?            |
| `5`         | How do you find the training environment?         |

Unknown rating IDs or star values outside `1..5` are silently skipped.

## Behaviour

- The review is saved with `status = APPROVED` and appears on the
  storefront immediately.
- If `created_at` is supplied it is written to `review.created_at` after
  the normal `save()` (which would otherwise stamp `NOW()`).
- After votes are recorded the product's `review_entity_summary` is
  recomputed via `Mage_Review_Model_Review::aggregate()`.

## Responses

### 200 — Success

```json
{
  "success":    true,
  "review_id":  22863,
  "created_at": "2026-04-10 04:00:17",
  "store_id":   1,
  "message":    "Review created and approved"
}
```

### Error codes

| HTTP | Cause                                                          |
|------|----------------------------------------------------------------|
| 400  | Invalid JSON, missing required field, or invalid `created_at`  |
| 401  | Missing or invalid `X-Api-Key`                                 |
| 404  | `product_id` not found                                         |
| 405  | Non-POST method                                                |
| 500  | Server error (detail in response body)                         |

## Idempotency

Each successful call creates a **new** `review_id`. Re-posting the same
payload produces a duplicate review. Callers must dedupe upstream (e.g.
record the returned `review_id` against the source row).

## cURL example

```bash
curl -X POST 'https://www.tertiarycourses.com.sg/kael_review_api.php' \
  -H 'Content-Type: application/json' \
  -H "X-Api-Key: $KAEL_REVIEW_API_KEY" \
  -d '{
    "product_id":  1362,
    "nickname":    "John Tan",
    "title":       "Average Rating: 4.7/5",
    "detail":      "Great course, very informative!",
    "ratings":     {"1": 5, "2": 5, "5": 4},
    "created_at":  "2026-04-10 04:00:17"
  }'
```

## Python example

```python
import os, requests

resp = requests.post(
    "https://www.tertiarycourses.com.sg/kael_review_api.php",
    headers={
        "Content-Type": "application/json",
        "X-Api-Key":    os.environ["KAEL_REVIEW_API_KEY"],
    },
    json={
        "product_id":  1362,
        "nickname":    "John Tan",
        "title":       "Average Rating: 4.7/5",
        "detail":      "Great course, very informative!",
        "ratings":     {"1": 5, "2": 5, "5": 4},
        "created_at":  "2026-04-10 04:00:17",
    },
    timeout=20,
)
resp.raise_for_status()
print(resp.json())
```
