# Survey Explorer 1 Dispatch: Security & Multi-Tenancy (R1)
Date: 2026-09-13T23:37:35Z
Target Scope:
1. Hardcoded Supabase credentials in `lib/main.dart` and environment variable handling with startup validation (`assert` / startup checks).
2. Supabase RLS policies in `supabase_migration_v10_canonical_v2.sql` and database schemas (eliminate `OR empresa_id IS NULL`, enforce strict multi-tenancy).
3. User/team member creation validation, admin permissions, password hashing / credential security.
Original Request: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md
Working Directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_explorer_1
Output file: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_explorer_1\handoff.md
