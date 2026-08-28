# Demo sandbox

## Entry point

- Production: `https://mtd-evidence-rail.sociobot.in/demo`
- Local: `http://localhost:8080/demo`

The visible **Try it with sample data** link reaches this route in one click.
Opening `/demo` provisions a random server-side workspace with a 24-hour expiry.

## Sample records

The demo starts in Q2 2026 with six transactions:

- two income invoices for tutoring and club fees;
- four expenses for stationery, venue hire, travel, and teaching materials;
- four linked evidence files and two transactions without evidence.

This supports missing-evidence review, CSV matching, evidence linking, and ZIP
export without setup.

## Isolation and reset

The browser key is `demo:mtd-evidence-rail:workspace` in `sessionStorage`.
Private workspaces use `mtd-evidence-rail:workspace` in `localStorage`. The demo
API workspace id begins with `demo:`. Every read and write carries only the
active workspace key.

**Reset demo** discards the session key and provisions a fresh sample workspace.
**Start for real** opens `/app`, where a separate private key is created. Demo
records are never copied into the private workspace.

The backend refuses expired demo keys. Each new demo also removes expired demo
workspaces and their records through database cascade deletion.
