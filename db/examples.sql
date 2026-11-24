insert into sklypu_vertinimai (sklypo_id, vertinimo_teritorijos_id, persidengimo_dalis, sukurimo_laikas, geom)
select 
	s.id as sklypo_id,
	1,
	st_area(
		st_intersection(
			s.geom, 
			(select geom from vertinimo_teritorijos)
		)
	)/ st_area(s.geom) as persidengimo_dalis,
	now() as sukurimo_laikas,
	st_intersection(
		s.geom, 
		(select geom from vertinimo_teritorijos)
	) as geom
from sklypai s
where 
	st_intersects(
		s.geom, 
		(select geom from vertinimo_teritorijos)
	);