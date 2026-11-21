#import "notes.typ": *
#import "plots.typ": lq, plot-style

#show: notes.with(
  title: "Connection Pooling in Practice",
  subtitle: "Why reuse beats reconnect",
  author: "Lucas Neumann",
  abstract: [A pool keeps open database connections and lends them to requests. This note measures the handshake cost it removes and shows how to size the pool.],
)
#show: plot-style

= Problem

Every new connection pays a TCP and TLS handshake plus authentication. At high request rates this fixed cost dominates query time.#footnote[Measured on PostgreSQL 17 over a 1 ms LAN link.] Typical text should stay between 45 and 90 characters per line, so the measure of this template targets about 75.

#note(title: "Key point")[Size the pool from the database side: `max_connections` minus headroom, divided by app instances.]

== Measurement

@tab:latency compares median latency. @fig:latency shows how it scales.

#figure(
  table(
    columns: 3,
    [Mode], [Median (ms)], [p99 (ms)],
    [New connection], [12.4], [31.0],
    [Pooled], [0.9], [2.7],
    [Pooled + prepared], [0.6], [1.9],
  ),
  caption: [Query latency by connection mode, 10k requests.],
) <tab:latency>

#figure(
  lq.diagram(
    xlabel: [Requests per second],
    ylabel: [Median latency (ms)],
    lq.plot((100, 500, 1000, 2000), (11.8, 12.4, 14.9, 22.3), label: [New], mark: "o"),
    lq.plot((100, 500, 1000, 2000), (0.8, 0.9, 1.0, 1.4), label: [Pooled], mark: "s"),
  ),
  caption: [Latency grows with load only without a pool.],
  alt: "Line chart: new-connection latency rises from 11.8 to 22.3 ms between 100 and 2000 requests per second; pooled stays near 1 ms.",
) <fig:latency>

=== Configuration

```python
pool = create_pool(dsn, min_size=2, max_size=20, max_idle=300)
async with pool.acquire() as conn:
    rows = await conn.fetch("SELECT 1")
```

Pool size per instance, with $h$ connections reserved for admin and $k$ app instances:

$ N = (C_"max" - h) / k $
