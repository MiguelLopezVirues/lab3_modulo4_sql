
-- 1.1 promedio más alto y más bajo o el maximo o minimo
SELECT municipio, MIN(temp_celsius) maximo_temp, MAX(temp_celsius) minimo_temp
FROM weather
NATURAL JOIN municipios m
GROUP BY municipio ;

WITH promedios_temp AS (
SELECT municipio, ROUND(AVG(temp_celsius),2) promedio_temp
FROM municipios m 
INNER JOIN weather w 
	ON w.id_municipio = m.id_municipio 
GROUP BY municipio)

SELECT MIN(promedio_temp) promedio_minimo, MAX(promedio_temp) promedio_maximo
FROM promedios_temp;

-- 1.2. Obtén los municipios en los cuales coincidan las medias de la sensación térmica y de la temperatura. 
SELECT municipio
FROM municipios m 
INNER JOIN weather w 
	ON w.id_municipio = m.id_municipio 
GROUP BY municipio
HAVING AVG(w.temp_celsius) =  AVG(sen_termica_celsius); 


-- 1.3. Obtén el local más cercano de cada municipio
					
    								
WITH distancias AS (
SELECT m.id_municipio,municipio, location_name,  6371000 * acos( cos( radians(m.latitude) ) 
    * cos( radians(fl.latitude) ) 
    * cos( radians(fl.longitude) - radians(m.longitude) ) 
    + sin( radians(m.latitude) ) 
    * sin( radians(fl.latitude) ) ) AS distancia_m
FROM municipios m 
CROSS JOIN foursquare_location fl),

min_distancias AS (
    SELECT municipio, MIN(distancia_m) AS min_distancia_m
    FROM distancias
    GROUP BY municipio
)

SELECT d.municipio, d.location_name, d.distancia_m
FROM distancias d
JOIN min_distancias md
    ON d.municipio = md.municipio AND d.distancia_m = md.min_distancia_m;
    								

-- 1.4. Localiza los municipios que posean algún localizador a una distancia mayor de 2000 y que posean al menos 25 locales.
WITH distancias AS (
SELECT m.id_municipio,municipio, location_name,  6371000 * acos( cos( radians(m.latitude) ) 
    * cos( radians(fl.latitude) ) 
    * cos( radians(fl.longitude) - radians(m.longitude) ) 
    + sin( radians(m.latitude) ) 
    * sin( radians(fl.latitude) ) ) AS distancia_m
FROM municipios m 
CROSS JOIN foursquare_location fl
WHERE 6371000 * acos( cos( radians(m.latitude) ) 
    * cos( radians(fl.latitude) ) 
    * cos( radians(fl.longitude) - radians(m.longitude) ) 
    + sin( radians(m.latitude) ) 
    * sin( radians(fl.latitude) ) ) > 2000 )

   
SELECT m.municipio
FROM foursquare_location fl 
INNER JOIN municipios m 
	ON m.id_municipio = fl.id_municipio 
INNER JOIN distancias d
	ON d.id_municipio = m.id_municipio 
GROUP BY m.municipio
HAVING COUNT(fl.location_name) >= 25;
   
   

-- 1.5. Teniendo en cuenta que el viento se considera leve con una velocidad media de entre 6 y 20 km/h, moderado con una media de entre 21 y 40 km/h, fuerte con media de entre 41 y 70 km/h y muy fuerte entre 71 y 120 km/h. Calcula cuántas rachas de cada tipo tenemos en cada uno de los días. Este ejercicio debes solucionarlo con la sentencia CASE de SQL (no la hemos visto en clase, por lo que tendrás que buscar la documentación). 
SELECT CASE 
		WHEN 0 <= velocidad_viento AND  velocidad_viento < 6 THEN 'no_viento' -- NO uso BETWEEN por tener los intervalos cerrados
		WHEN 6 <= velocidad_viento AND  velocidad_viento < 21 THEN 'viento_leve'
		WHEN 21 <= velocidad_viento AND  velocidad_viento < 41 THEN 'viento_moderado'
		WHEN 41 <= velocidad_viento AND  velocidad_viento < 71 THEN 'viento_fuerte'
		WHEN 71 <= velocidad_viento AND  velocidad_viento < 120 THEN 'viento_mu_fuerte'
		ELSE 'huracan'
		END AS gravedad_viento
FROM weather w;




-- ## Ejercicio 2. Vistas

-- 2.1. Crea una vista que muestre la información de los locales que tengan incluido el código postal en su dirección. 
CREATE VIEW vista_1 AS
SELECT location_name, address
FROM foursquare_location fl 
WHERE address ~ '\d{5}';



-- 2.2. Crea una vista con los locales que tienen más de una categoría asociada.
CREATE VIEW vista_2 AS -- los locales NO pueden tener mas de una categoria asociada, así que lo hago con los pueblos
SELECT municipio
FROM municipios m 
INNER JOIN foursquare_location fl 
	ON fl.id_municipio = m.id_municipio
GROUP BY municipio
HAVING COUNT(DISTINCT category) > 1;


-- 2.3. Crea una vista que muestre el municipio con la temperatura más alta de cada día
CREATE VIEW vista_3 AS
SELECT municipio, dia, promedio
FROM (
SELECT municipio, EXTRACT(DAY FROM w.fecha) AS dia, AVG(temp_celsius) promedio, MAX(AVG(temp_celsius)) OVER (PARTITION BY EXTRACT(DAY FROM w.fecha))
FROM municipios m 
INNER JOIN weather w 
	ON w.id_municipio = m.id_municipio
GROUP BY municipio, EXTRACT(DAY FROM w.fecha))
WHERE promedio = max;



-- 2.4. Crea una vista con los municipios en los que haya una probabilidad de precipitación mayor del 100% durante mínimo 7 horas.
-- lo voy a hacer de los que tengan mm de precipitación mas de 0
CREATE VIEW vista_4 AS
SELECT municipio
FROM municipios m 
INNER JOIN weather w
	ON m.id_municipio = w.id_municipio 
WHERE w.precipitacion_mm > 0 
GROUP BY municipio 
HAVING COUNT(*) >= 7;


-- 2.5. Obtén una lista con los parques de los municipios que tengan algún castillo.

SELECT location_name 
FROM municipios m 
INNER JOIN foursquare_location fl 
	ON fl.id_municipio = m.id_municipio 
WHERE category = 'Park' AND EXISTS (SELECT 1 
									FROM foursquare_location fl2
									WHERE fl2.id_municipio = fl.id_municipio
										AND fl2.category = 'Castle');

	
-- ## Ejercicio 3. Tablas Temporales

-- 3.1. Crea una tabla temporal que muestre cuántos días han pasado desde que se obtuvo la información de la tabla AEMET.
CREATE TEMPORARY TABLE temp_table1 AS
SELECT EXTRACT (DAY FROM now() - MAX(fecha)) dias_desde_ultimo_forecast
FROM weather w ;

-- 3.2. Crea una tabla temporal que muestre los locales que tienen más de una categoría asociada e indica el conteo de las mismas
-- los locales NO pueden tener mas de una categoria asociada, así que lo hago con los pueblos
CREATE TEMPORARY TABLE temp_table2 AS
SELECT municipio, COUNT(DISTINCT category)
FROM municipios m 
INNER JOIN foursquare_location fl 
	ON fl.id_municipio = m.id_municipio
GROUP BY municipio
HAVING COUNT(DISTINCT category) > 1;


-- 3.3. Crea una tabla temporal que muestre los tipos de cielo para los cuales la probabilidad de precipitación mínima de los promedios de cada día es 5.
-- no tengo riesgos de precipitacion, así que lo hago con los mm de precipitacion > 5mm
CREATE TEMPORARY TABLE temp_table3 AS
SELECT cielo, AVG(precipitacion_mm) promedio_precip
FROM weather w 
GROUP BY cielo
HAVING AVG(precipitacion_mm) > 5;

-- 3.4. Crea una tabla temporal que muestre el tipo de cielo más y menos repetido por municipio.
CREATE TEMPORARY TABLE temp_table4 AS 
SELECT  municipio,
                      (SELECT cielo
                      FROM municipios m_sub
                      INNER JOIN weather w_sub
                           ON m_sub.id_municipio = w_sub.id_municipio
                      WHERE m.id_municipio = m_sub.id_municipio
                      GROUP BY cielo
                      ORDER BY COUNT(*) DESC
                      LIMIT 1) cielo_mas_repetido,
                      (SELECT cielo
                      FROM municipios m_sub
                      INNER JOIN weather w_sub
                           ON m_sub.id_municipio = w_sub.id_municipio
                      WHERE m.id_municipio = m_sub.id_municipio
                      GROUP BY cielo
                      ORDER BY COUNT(*) ASC
                      LIMIT 1) cielo_meno_repetido
                      
FROM municipios m ;


-- ## Ejercicio 4. SUBQUERIES

-- 4.1. Necesitamos comprobar si hay algún municipio en el cual no tenga ningún local registrado.
SELECT municipio 
FROM municipios m 
WHERE NOT EXISTS (SELECT 1
				FROM foursquare_location fl
				WHERE fl.id_municipio = m.id_municipio);


-- 4.2. Averigua si hay alguna fecha en la que el cielo se encuente "Muy nuboso con tormenta".
SELECT COUNT(*)
FROM weather w 
WHERE EXISTS (SELECT 1
				FROM weather w_sub
				WHERE w_sub.fecha = w.fecha
					AND w_sub.id_municipio = w.id_municipio 
					AND cielo = 'Muy nuboso con tormenta');
				
SELECT COUNT(*)
FROM weather w 
WHERE cielo = 'Muy nuboso con tormenta';

-- 4.3. Encuentra los días en los que los avisos sean diferentes a "Sin riesgo".
-- me quité los avisos, así que lo voy a hacer con direccion de viento 'SE'
SELECT DISTINCT EXTRACT (DAY FROM fecha), id_municipio
FROM weather w 
WHERE EXISTS (SELECT 1
				FROM weather w_sub
				WHERE w_sub.fecha = w.fecha
					AND w_sub.id_municipio = w.id_municipio 
					AND direccion_viento = 'SE')


-- 4.4. Selecciona el municipio con mayor número de locales.
SELECT municipio, COUNT(*)
FROM municipios m 
INNER JOIN foursquare_location fl 
	ON fl.id_municipio = m.id_municipio 
GROUP BY m.id_municipio
ORDER BY COUNT(*) DESC
LIMIT 1;


-- forzando la subconsulta
WITH locales AS 
(SELECT municipio, COUNT(*) n_locales
			FROM municipios m 
			INNER JOIN foursquare_location fl 
				ON fl.id_municipio = m.id_municipio 
			GROUP BY m.id_municipio
			ORDER BY COUNT(*) DESC)
SELECT municipio
FROM municipios m 
INNER JOIN foursquare_location fl 
	ON fl.id_municipio = m.id_municipio 
GROUP BY municipio 
HAVING COUNT(*) = (SELECT MAX(n_locales) FROM locales);

-- 4.5. Obtén los municipios muya media de sensación térmica sea mayor que la media total.

SELECT  municipio
FROM municipios m 
INNER JOIN weather w 
	ON w.id_municipio = m.id_municipio 
GROUP BY municipio
HAVING AVG(sen_termica_celsius) > (SELECT AVG(sen_termica_celsius) FROM weather w );


	
	
	
	
	

