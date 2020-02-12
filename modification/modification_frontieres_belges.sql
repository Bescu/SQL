/*
Méthode 3 : modification des frontières belges par rapport aux frontières françaises afin d'avoir des limites jointives, via un découpage par ligne
*/


-- Création du contour MEL sous frome de ligne
INSERT INTO ta_test_lignes(geom)
SELECT SDO_UTIL.POLYGONTOLINE((SELECT
    SDO_AGGR_UNION(
        SDOAGGRTYPE(a.geom, 0.001)
    ) AS geom
FROM
    ta_test_limites_communes a
WHERE
    a.geom IS NOT NULL
    AND a.fid_source = 3)
)
FROM DUAL;

-- Découpage de la ligne afin de ne garder que les éléments de la ligne qui sont à 50m maximum de l'union des municipalités belges
INSERT INTO ta_test_lignes(geom)
WITH
    v_buffer AS (
    SELECT
        SDO_GEOM.SDO_BUFFER(c.geom, 50, 0.001) AS geom
    FROM
        (SELECT
            SDO_AGGR_UNION(
                SDOAGGRTYPE(a.geom, 0.001)
            ) AS geom
        FROM
            ta_test_limites_communes a
        WHERE
            a.geom IS NOT NULL
            AND a.fid_source = 25) c
    )
    
    SELECT
        SDO_GEOM.SDO_INTERSECTION(a.geom, b.geom, 0.001)
    FROM
        ta_test_lignes a,
        v_buffer b
    WHERE
        a.objectid = 22;


-- Création de lignes à partir de points
INSERT INTO ta_test_lignes(geom)
SELECT --objectid,
        --substr(sdo_geom.validate_geometry(linestring,0.005),1,5) AS vLine,
       linestring
  FROM (SELECT
                c.objectid,
               mdsys.sdo_geometry(2002,2154,NULL,
                                  mdsys.sdo_elem_info_array(1,2,1),
                                  CAST(MULTISET(SELECT b.COLUMN_VALUE
                                                  FROM ta_test_points a,
                                                       TABLE(mdsys.sdo_ordinate_array(a.geom.sdo_point.x,
                                                                                      a.geom.sdo_point.y)) b
                                                 WHERE a.fid_source = 3
                                                 ORDER BY a.FID_ORDER_POINT, rownum)
                                  AS mdsys.sdo_ordinate_array)) AS linestring
          FROM ta_test_points c
          GROUP BY c.OBJECTID
          ORDER BY c.OBJECTID
  ) f;

  -- Concaténation de plusieurs lignes pour n'en créer qu'une
   INSERT INTO ta_test_lignes(fid_source, geom)
    SELECT
     3,
     SDO_AGGR_UNION(
            SDOAGGRTYPE(a.geom, 0.001)
        ) AS geom
    --SDO_LRS.CONCATENATE_GEOM_SEGMENTS(
    FROM
        TA_TEST_LIGNES a
    ;