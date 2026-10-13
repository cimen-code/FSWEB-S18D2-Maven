-- S18D2 - SQL DML, functions and procedures
-- Execute only against the dedicated workintech_s18d2 database.

DO $guard$
BEGIN
    IF (SELECT COUNT(*) FROM public.ogrenci) <> 10
       OR (SELECT COUNT(*) FROM public.kitap) <> 12
       OR (SELECT COUNT(*) FROM public.yazar) <> 5
       OR (SELECT COUNT(*) FROM public.tur) <> 5
       OR (SELECT COUNT(*) FROM public.islem) <> 17
       OR (SELECT puan FROM public.kitap WHERE kitapno = 1)
           IS DISTINCT FROM 22
       OR (SELECT COUNT(*) FROM public.ogrenci WHERE sinif = '10B') <> 2
    THEN
        RAISE EXCEPTION
            'Expected fresh S18D2 seed data. No changes applied.';
    END IF;
END;
$guard$;

-- 1. Biyografi turunu ekle
INSERT INTO public.tur (ad)
VALUES ('Biyografi');

-- 2. Nurettin Belek yazarini ekle
INSERT INTO public.yazar (ad, soyad)
VALUES ('Nurettin', 'Belek');

-- 3. 10B ogrencilerini 10C sinifina tasi
UPDATE public.ogrenci
SET sinif = '10C'
WHERE sinif = '10B';

-- 4. Butun kitaplarin puanini 5 artir
UPDATE public.kitap
SET puan = puan + 5;

-- 5. Adi Mehmet olan yazarlari sil
DELETE FROM public.yazar
WHERE ad = 'Mehmet';

-- 6. Kisisel Gelisim turunu ekle
INSERT INTO public.tur (ad)
VALUES ('Kişisel Gelişim');

-- 7. Benim Universitelerim kitabinin turunu degistir
UPDATE public.kitap
SET turno = (
    SELECT turno
    FROM public.tur
    WHERE ad = 'Kişisel Gelişim'
)
WHERE ad = 'Benim Üniversitelerim';

-- 8. Ogrenci listesi fonksiyonu
CREATE OR REPLACE FUNCTION public.ogrencilistesi()
RETURNS SETOF public.ogrenci
LANGUAGE sql
STABLE
AS $function$
    SELECT *
    FROM public.ogrenci
    ORDER BY ogrno;
$function$;

-- 9. Kitap ekleme proseduru
CREATE OR REPLACE PROCEDURE public.ekle(
    IN p_ad varchar,
    IN p_puan integer,
    IN p_yazarno bigint,
    IN p_turno bigint
)
LANGUAGE plpgsql
AS $procedure$
BEGIN
    INSERT INTO public.kitap (ad, puan, yazarno, turno)
    VALUES (p_ad, p_puan, p_yazarno, p_turno);
END;
$procedure$;

-- 10. Ogrenci silme proseduru
CREATE OR REPLACE PROCEDURE public.sil(
    IN p_ogrno bigint
)
LANGUAGE plpgsql
AS $procedure$
BEGIN
    DELETE FROM public.ogrenci
    WHERE ogrno = p_ogrno;
END;
$procedure$;

-- Verify results before committing the transaction.
DO $verify$
BEGIN
    IF (SELECT COUNT(*) FROM public.ogrenci WHERE sinif = '10C') <> 2
       OR (SELECT COUNT(*) FROM public.tur
           WHERE ad IN ('Biyografi', 'Kişisel Gelişim')) <> 2
       OR (SELECT COUNT(*) FROM public.yazar
           WHERE ad = 'Nurettin' AND soyad = 'Belek') <> 1
       OR EXISTS (
           SELECT 1 FROM public.yazar WHERE ad = 'Mehmet'
       )
       OR (SELECT puan FROM public.kitap WHERE kitapno = 1)
           IS DISTINCT FROM 27
       OR (SELECT COUNT(*) FROM public.ogrencilistesi()) <> 10
       OR (SELECT COUNT(*)
           FROM pg_proc
           WHERE pronamespace = 'public'::regnamespace
             AND proname IN ('ekle', 'sil')
             AND prokind = 'p') <> 2
    THEN
        RAISE EXCEPTION
            'S18D2 verification failed. Roll back transaction.';
    END IF;
END;
$verify$;
