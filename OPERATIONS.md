# Alpha Blog operations

The supported product is a moderated multi-author publication. Authors draft and revise; a different editor must approve and publish. Public readers only see published records. Every editorial transition, import, export, login, and media operation is attributable in `audit_events`.

Copy `.env.example` to a secret-managed environment. Production refuses to start without the database, host, and cookie-signing secret. `bin/start` never creates a database, seeds data, resets data, or kills another process. Set `RUN_MIGRATIONS=true` only in the single release job that owns migrations.

Back up the PostgreSQL database and `MEDIA_ROOT` together. Test restore regularly. An administrator can download a portable JSON archive from `/export` and restore it through `/import`; that archive supplements, but does not replace, physical database backups.

Deploy the immutable container behind TLS. Use `/articles` as the availability probe. Logs carry Rails request IDs; audit events are the business evidence stream. Alert on repeated 429/403 responses, failed migrations, database saturation, and a growing moderation queue.

Media is restricted to JPEG, PNG, and WebP, checked by signature, capped at 5 MiB, stored outside the public tree, and requires alternative text. A production object-store adapter can replace `Publishing::MediaStore` without weakening validation.
