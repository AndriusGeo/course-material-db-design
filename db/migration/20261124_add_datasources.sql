/*
  Sukuriama schema, kurioje bus saugomi oringalus duomenu saltiniai projekto duomenu naujinimui
*/


-- Sukuriama nauja schema
CREATE SCHEMA IF NOT EXISTS duomenu_saltiniai;

-- Atnaujinami vertinimo teritoriju duomenys - STVK

delete from vertinimo_teritorijos
where saltinio_id = 1;

insert into vertinimo_teritorijos(saltinio_id, saltinio_objekto_id, saltinio_pavadinimas, geom)
select
	1,
	id as saltinio_objekto_id,
	"PAVADINIMAS" as saltinio_pavadinimas,
	geom
from duomenu_saltiniai.stvk_draustiniai;

insert into vertinimo_teritorijos(saltinio_id, saltinio_objekto_id, saltinio_pavadinimas, geom)
select
	1,
	id as saltinio_objekto_id,
	"PAVADINIMAS" as saltinio_pavadinimas,
	geom
from duomenu_saltiniai.stvk_parkai;