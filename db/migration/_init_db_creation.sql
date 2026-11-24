/*
	Priskiriame numatytasias vartotoju grupiu privilegijas
*/

-- Sukuriamos roles

DROP ROLE IF EXISTS sklypu_redagavimas;
CREATE ROLE sklypu_redagavimas;
COMMENT ON ROLE sklypu_redagavimas IS 'Role, suteikianti teises redaguoti visus sklypu duomenu bazes duomenis';

DROP ROLE IF EXISTS sklypu_skaitymas;
CREATE ROLE sklypu_skaitymas;
COMMENT ON ROLE sklypu_skaitymas IS 'Role, suteikianti teises skaityti visus sklypu duomenu bazes duomenis';

-- Sukuriamos privilegijos

GRANT USAGE ON SCHEMA public TO sklypu_redagavimas;
GRANT USAGE ON SCHEMA public TO sklypu_skaitymas;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT INSERT, SELECT, UPDATE ON TABLES TO sklypu_redagavimas;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT SELECT ON TABLES TO sklypu_skaitymas;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT ALL ON SEQUENCES TO sklypu_redagavimas;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT SELECT ON SEQUENCES TO sklypu_skaitymas;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT EXECUTE ON FUNCTIONS TO sklypu_redagavimas;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT EXECUTE ON FUNCTIONS TO sklypu_skaitymas;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT USAGE ON TYPES TO sklypu_redagavimas;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT USAGE ON TYPES TO sklypu_skaitymas;


/*
	Prideti reikalingus pletinius
*/

CREATE EXTENSION IF NOT EXISTS postgis;

/*
	Sukurti reikiama duomenu bazes struktura
*/

CREATE TABLE IF NOT EXISTS "sklypai" (
	"id" SERIAL,
	"kadastrinis_nr" VARCHAR(32) NOT NULL UNIQUE,
	"unikalus_nr" VARCHAR(16) NOT NULL UNIQUE,
	-- Registruotas sklypo plotas, kv. m.
	"plotas" NUMERIC(14,2) NOT NULL,
	"statuso_id" INTEGER NOT NULL,
	"paskirties_id" INTEGER NOT NULL,
	"sukurimo_laikas" TIMESTAMPTZ NOT NULL DEFAULT now(),
	"atnaujinimo_laikas" TIMESTAMPTZ,
	"geom" GEOMETRY(MULTIPOLYGON,3346) NOT NULL,
	PRIMARY KEY("id")
);

COMMENT ON TABLE "sklypai" IS 'Pagrindinis sklypų geometrinis sluoksnis';
COMMENT ON COLUMN "sklypai"."plotas" IS 'Registruotas sklypo plotas, kv. m.';

CREATE INDEX "sklypai_statuso_id_idx"
ON "sklypai" ("statuso_id");
CREATE INDEX "sklypai_paskirties_id_idx"
ON "sklypai" ("paskirties_id");

CREATE TABLE IF NOT EXISTS "klasifikatoriai_statusai" (
	"id" SERIAL,
	"kodas" SMALLINT NOT NULL UNIQUE,
	"reiksme" VARCHAR(255) NOT NULL,
	PRIMARY KEY("id")
);

COMMENT ON TABLE "klasifikatoriai_statusai" IS 'Klasifikatorius sklypo statusui aprašyti';

CREATE TABLE IF NOT EXISTS "vertinimo_teritorijos" (
	"id" SERIAL,
	"saltinio_id" INTEGER NOT NULL,
	-- Objekto ID pirminiame rinkinyje
	"saltinio_objekto_id" VARCHAR(100),
	-- Pvz. našumo balas arba kategorijos kodas; tuščia binariniams sluoksniams
	"vertinimo_reiksme" NUMERIC,
	"sukurimo_laikas" TIMESTAMPTZ NOT NULL DEFAULT now(),
	"geom" GEOMETRY(MULTIPOLYGON,3346) NOT NULL,
	PRIMARY KEY("id")
);

COMMENT ON TABLE "vertinimo_teritorijos" IS 'Visų šaltinių plotiniai objektai, naudojami sklypų vertinimui';
COMMENT ON COLUMN "vertinimo_teritorijos"."saltinio_objekto_id" IS 'Objekto ID pirminiame rinkinyje';
COMMENT ON COLUMN "vertinimo_teritorijos"."vertinimo_reiksme" IS 'Pvz. našumo balas arba kategorijos kodas; tuščia binariniams sluoksniams';

CREATE INDEX "vertinimo_teritorijos_saltinio_id_idx"
ON "vertinimo_teritorijos" ("saltinio_id");

CREATE TABLE IF NOT EXISTS "duomenu_saltiniai" (
	"id" SERIAL,
	-- Trumpas kodas, pvz. stvk_draustiniai
	"kodas" VARCHAR(50) NOT NULL UNIQUE,
	"rinkinio_pavadinimas" VARCHAR(255) NOT NULL,
	"rinkinio_autorius" VARCHAR(255) NOT NULL,
	"rinkinio_url" TEXT,
	-- Duomenų būklės data
	"rinkinio_data" DATE,
	"importo_laikas" TIMESTAMPTZ,
	-- vertinimo_reiksme matavimo vienetai, jei yra
	"matavimo_vnt" VARCHAR(50),
	"aprasymas" TEXT,
	PRIMARY KEY("id")
);

COMMENT ON TABLE "duomenu_saltiniai" IS 'Vertinimo teritorijų duomenų šaltinių aprašas';
COMMENT ON COLUMN "duomenu_saltiniai"."kodas" IS 'Trumpas kodas, pvz. stvk_draustiniai';
COMMENT ON COLUMN "duomenu_saltiniai"."rinkinio_data" IS 'Duomenų būklės data';
COMMENT ON COLUMN "duomenu_saltiniai"."matavimo_vnt" IS 'vertinimo_reiksme matavimo vienetai, jei yra';

CREATE TABLE IF NOT EXISTS "sklypu_vertinimai" (
	"id" SERIAL NOT NULL,
	"sklypo_id" INTEGER NOT NULL,
	"vertinimo_teritorijos_id" INTEGER NOT NULL,
	-- 0–1, susikirtimo plotas / sklypo plotas
	"persidengimo_dalis" NUMERIC(7,6) NOT NULL,
	-- vertinimo_reiksme × persidengimo_dalis; tuščia, jei šaltinis neturi skaitinės reikšmės
	"persidengimo_reiksme" NUMERIC,
	"sukurimo_laikas" TIMESTAMPTZ NOT NULL DEFAULT now(),
	-- Susikirtimo geometrija
	"geom" GEOMETRY(MULTIPOLYGON,3346) NOT NULL,
	PRIMARY KEY("id")
);

COMMENT ON TABLE "sklypu_vertinimai" IS 'Sklypų ir vertinimo teritorijų susikirtimai';
COMMENT ON COLUMN "sklypu_vertinimai"."persidengimo_dalis" IS '0–1, susikirtimo plotas / sklypo plotas';
COMMENT ON COLUMN "sklypu_vertinimai"."persidengimo_reiksme" IS 'vertinimo_reiksme × persidengimo_dalis; tuščia, jei šaltinis neturi skaitinės reikšmės';
COMMENT ON COLUMN "sklypu_vertinimai"."geom" IS 'Susikirtimo geometrija';

CREATE UNIQUE INDEX "sklypu_vertinimai_sklypas_vt_uq"
ON "sklypu_vertinimai" ("sklypo_id", "vertinimo_teritorijos_id");
CREATE INDEX "sklypu_vertinimai_vt_id_idx"
ON "sklypu_vertinimai" ("vertinimo_teritorijos_id");

CREATE TABLE IF NOT EXISTS "klasifikatoriai_paskirtys" (
	"id" SERIAL,
	"kodas" SMALLINT NOT NULL UNIQUE,
	"reiksme" VARCHAR(255) NOT NULL,
	PRIMARY KEY("id")
);

COMMENT ON TABLE "klasifikatoriai_paskirtys" IS 'Klasifikatorius sklypo paskirčiai aprašyti';

ALTER TABLE "sklypai"
ADD FOREIGN KEY("statuso_id") REFERENCES "klasifikatoriai_statusai"("id")
ON UPDATE NO ACTION ON DELETE RESTRICT;
ALTER TABLE "sklypu_vertinimai"
ADD FOREIGN KEY("sklypo_id") REFERENCES "sklypai"("id")
ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE "sklypai"
ADD FOREIGN KEY("paskirties_id") REFERENCES "klasifikatoriai_paskirtys"("id")
ON UPDATE NO ACTION ON DELETE RESTRICT;
ALTER TABLE "vertinimo_teritorijos"
ADD FOREIGN KEY("saltinio_id") REFERENCES "duomenu_saltiniai"("id")
ON UPDATE NO ACTION ON DELETE RESTRICT;
ALTER TABLE "sklypu_vertinimai"
ADD FOREIGN KEY("vertinimo_teritorijos_id") REFERENCES "vertinimo_teritorijos"("id")
ON UPDATE NO ACTION ON DELETE CASCADE;

/*
	Sukurti erdvinius indeksus
*/

-- Erdvinis indeksas sklypams
CREATE INDEX sklypai_geom_idx
  ON sklypai
  USING GIST (geom);

-- Erdvinis indeksas vertinimo teritorijoms
CREATE INDEX vertinimo_teritorijos_geom_idx
  ON vertinimo_teritorijos
  USING GIST (geom);

-- Erdvinis indeksas vertinimo teritorijoms
CREATE INDEX sklypu_vertinimai_geom_idx
  ON sklypu_vertinimai
  USING GIST (geom);


/*
	Klasifikatoriu uzpildymas
*/

INSERT INTO klasifikatoriai_statusai("kodas", "reiksme")
VALUES 
	(1, 'nuomojamas'),
	(2, 'dirbamas'),
	(3, 'parduodamas');

INSERT INTO klasifikatoriai_paskirtys("kodas", "reiksme")
VALUES 
	(1, 'komercinė'),
	(2, 'žemės ūkio'),
	(3, 'kita');