## 2026-08-31T19:52:38Z
Task:
1. Read ORIGINAL_REQUEST.md.
2. Thoroughly investigate the database schema, SQL migrations, repository classes, Supabase service layer, and queries in c:\Users\Freddy\Desktop\Desarrollo de app\FishBit:
   - Identify all queries, repositories, and edge functions/RPCs dealing with:
     * parametros_calidad_agua
     * alimentacion_diaria
     * lotes
     * biometrias
     * mortalidad
     * traslados_lotes
   - Identify missing composite indexes, particularly on (empresa_id, fecha DESC) or (empresa_id, lote_id, fecha DESC) and foreign keys.
   - Inspect RLS (Row Level Security) policies across all tables for performance traps (e.g. unindexed auth.uid() lookups, correlated subqueries in USING clauses, nested SELECTs).
   - Inspect query patterns in Dart repositories (e.g., SELECT *, missing limits/pagination, N+1 queries).
3. Produce a detailed diagnostic and optimization plan report in c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_survey_be\handoff.md including precise SQL migration scripts, index definitions, RLS refactorings, and repository query optimizations.
4. Send a message to the orchestrator when finished.
