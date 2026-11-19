-- Migración: Preferencias operativas en empresas + Storage bucket fishbit-media para avatares y logos

ALTER TABLE public.empresas
  ADD COLUMN IF NOT EXISTS preferencias_operativas jsonb NOT NULL DEFAULT '{}'::jsonb;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'fishbit-media',
  'fishbit-media',
  true,
  2097152,
  ARRAY['image/png', 'image/jpeg', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Lectura pública de avatares y logos
DROP POLICY IF EXISTS "fishbit_media_public_read" ON storage.objects;
CREATE POLICY "fishbit_media_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'fishbit-media');

-- Avatares: cada usuario autenticado gestiona su carpeta avatars/<auth.uid()>/*
DROP POLICY IF EXISTS "fishbit_media_avatar_insert" ON storage.objects;
CREATE POLICY "fishbit_media_avatar_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'fishbit-media'
    AND (storage.foldername(name))[1] = 'avatars'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

DROP POLICY IF EXISTS "fishbit_media_avatar_update" ON storage.objects;
CREATE POLICY "fishbit_media_avatar_update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'fishbit-media'
    AND (storage.foldername(name))[1] = 'avatars'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

DROP POLICY IF EXISTS "fishbit_media_avatar_delete" ON storage.objects;
CREATE POLICY "fishbit_media_avatar_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'fishbit-media'
    AND (storage.foldername(name))[1] = 'avatars'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

-- Logos de empresa: miembros autenticados de esa empresa gestionan logos/<empresa_id>/*
DROP POLICY IF EXISTS "fishbit_media_logo_insert" ON storage.objects;
CREATE POLICY "fishbit_media_logo_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'fishbit-media'
    AND (storage.foldername(name))[1] = 'logos'
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.empresa_id::text = (storage.foldername(name))[2]
    )
  );

DROP POLICY IF EXISTS "fishbit_media_logo_update" ON storage.objects;
CREATE POLICY "fishbit_media_logo_update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'fishbit-media'
    AND (storage.foldername(name))[1] = 'logos'
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.empresa_id::text = (storage.foldername(name))[2]
    )
  );

DROP POLICY IF EXISTS "fishbit_media_logo_delete" ON storage.objects;
CREATE POLICY "fishbit_media_logo_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'fishbit-media'
    AND (storage.foldername(name))[1] = 'logos'
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.empresa_id::text = (storage.foldername(name))[2]
    )
  );
