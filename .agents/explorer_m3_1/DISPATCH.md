# Task Dispatch: Explorer M3_1 (Bento Card Touch Targets & Field Ergonomics — UX-01)

## Mission
Investigate `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart` to identify all interactive micro-buttons under 48x48 dp and design the WCAG 2.5.5 compliant operational action bottom sheet for aquaculture field use.

## Mandatory Paths to Read First
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md` (MANDATORY)
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_impl_gen2\PROJECT.md`
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart`

## Investigation Scope
1. Measure exact rendered dimensions / padding / constraints of all quick-action buttons on `PondBentoCard` (feeding, water quality, biometry, mortality, harvest/transfer).
2. Identify which buttons violate WCAG 2.5.5 (minimum 48x48 dp touch target).
3. Design the replacement pattern:
   - Primary high-visibility action button on card (>=48x48 dp).
   - Operational Bottom Sheet (`showModalBottomSheet`) grouping pond operations (Alimentar, Registrar Calidad de Agua, Muestreo Biometría, Registrar Baja, Traslado/Cosecha) with large, tactile buttons (>=56 dp height, full width) tailored for field technicians with wet or gloved hands.
4. Provide concrete code diffs and implementation recommendations for Worker M3.

Write report to:
`c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_1\handoff.md`
Notify orchestrator via `send_message`.

## 2026-09-14T14:35:47Z
You are Explorer M3_1.
Your working directory is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_1
Read your instructions in c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_1\DISPATCH.md.
MANDATORY: Read c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md first.
Investigate lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart for touch target sizes and design a WCAG 2.5.5 compliant operational bottom sheet for field actions.
Write your report to c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_1\handoff.md and notify orchestrator via send_message.
