/*
Objectif : créer une table de versionnement pour la table TA_LIG_TOPO_G, qui récupère toutes les modifications et suppression faites sur chaque objet de la table TA_LIG_TOPO_G (production).

Méthode :
Pour la table de production, on créé : 
  1. une table de versionnement ;
  2. un trigger qui incrémente la table de versionnement avec les modifications qu'il récupère dans la table de production ;
*/

-- 1. Création de la table de versionnement :
-- 1.1. Création de la table de versionnement TA_LIG_TOPO_G_LOG
CREATE TABLE GEO.TA_LIG_TOPO_G_LOG(
   OBJECTID NUMBER(38,0) NOT NULL ENABLE, 
  FID_IDENTIFIANT NUMBER(38,0) NOT NULL ENABLE, 
  CLA_INU NUMBER(8,0) NOT NULL ENABLE, 
  GEO_REF VARCHAR2(13 BYTE), 
  GEO_INSEE CHAR(3 BYTE), 
  GEOM SDO_GEOMETRY, 
  GEO_DV DATE, 
  GEO_DF DATE, 
  GEO_TEXTE VARCHAR2(2048 BYTE), 
    GEO_LIG_OFFSET_D NUMBER(8,0), 
    GEO_LIG_OFFSET_G NUMBER(8,0), 
    GEO_TYPE CHAR(1 BYTE), 
    GEO_NMN VARCHAR2(20 BYTE), 
    GEO_DM DATE,
  MODIFICATION NUMBER(38,0) NOT NULL ENABLE
);

-- 1.2. Création des commentaires pour la table et ses attributs
   COMMENT ON TABLE GEO.TA_LIG_TOPO_G_LOG  IS 'Table de versionnement de la table TA_LIG_TOPO_G. Elle contient toutes les mises à jour (à partir du 13.02.2020) et les suppressions de la table de production.';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.OBJECTID IS 'Identifiant interne de l''objet geographique';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.FID_IDENTIFIANT IS 'Identifiant de l''objet qui est/était présent dans la table de production.';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.CLA_INU IS 'Reference a la classe a laquelle appartient l''objet';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.GEO_REF IS 'Identifiant metier. Non obligatoire car certain objet geographique n''ont pas d''objet metier associe.';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.GEO_INSEE IS 'Code insee de la commune sur laquelle se situe l''objet';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.GEOM IS 'Geometrie ORACLE de l''objet';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.GEO_DV IS 'Date de debut de validite de l''objet';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.GEO_DF IS 'Date de fin de validite de l''objet.';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.GEO_TEXTE IS 'Texte de commentaire';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.GEO_LIG_OFFSET_D IS 'Decallage a droite par rapport a la generatrice';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.GEO_LIG_OFFSET_G IS 'Decallage a gauche par rapport a la generatrice';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.GEO_TYPE IS 'Type de geometrie de l''objet geographique';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.GEO_NMN IS 'Auteur de la derniere modification';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.GEO_DM IS 'Date de deniere modification de l''objet';
   COMMENT ON COLUMN GEO.TA_LIG_TOPO_G_LOG.MODIFICATION IS 'Type de modification effectuée sur la donnée : 1 = mise à jour, 0 = suppression';

-- 1.3. Création de la clé primaire de la table
ALTER TABLE TA_LIG_TOPO_G_LOG 
ADD CONSTRAINT TA_LIG_TOPO_G_LOG_PK 
PRIMARY KEY("OBJECTID") 
USING INDEX TABLESPACE "INDX_GEO";

-- 1.4. Création des métadonnées spatiales
INSERT INTO USER_SDO_GEOM_METADATA(
    TABLE_NAME, 
    COLUMN_NAME, 
    DIMINFO, 
    SRID
)
VALUES(
    'TA_LIG_TOPO_G_LOG',
    'geom',
    SDO_DIM_ARRAY(SDO_DIM_ELEMENT('X', 594000, 964000, 0.005),SDO_DIM_ELEMENT('Y', 6987000, 7165000, 0.005)), 
    2154
);
COMMIT;

-- 1.5. Création de l'index spatial sur le champ geom. Le type de géométrie n'est pas ici précisé car la table TA_LIG_TOPO_G dipose de 4 types de géométries (2006, 2000, 2003, 2002).
CREATE INDEX TA_LIG_TOPO_G_LOG_SIDX
ON TA_LIG_TOPO_G_LOG(GEOM)
INDEXTYPE IS MDSYS.SPATIAL_INDEX;

-- 1.6. Création de la séquence d'auto-incrémentation
CREATE SEQUENCE SEQ_TA_LIG_TOPO_G_LOG
START WITH 1 INCREMENT BY 1;

-- 1.7. Création du trigger d'incrémentation de la clé primaire
CREATE OR REPLACE TRIGGER "GEO"."BEF_TA_LIG_TOPO_G_LOG" 
BEFORE INSERT ON TA_LIG_TOPO_G_LOG
FOR EACH ROW

BEGIN
  :new.objectid := SEQ_TA_LIG_TOPO_G_LOG.nextval;
END;

-- 2. Création du trigger de récupération des modifications ou des suppressions de la table de production (TA_LIG_TOPO_G) qu'il insére dans la table de versionnement (TA_LIG_TOPO_G_LOG)
CREATE OR REPLACE TRIGGER trig_TA_LIG_TOPO_G_LOG
    BEFORE UPDATE OR DELETE ON TA_LIG_TOPO_G
    FOR EACH ROW
DECLARE
    username varchar(30);
    BEGIN
        SELECT sys_context('USERENV','OS_USER') into username from dual;  
        IF UPDATING THEN
             INSERT INTO GEO.TA_LIG_TOPO_G_LOG(FID_IDENTIFIANT, CLA_INU, GEO_REF, GEO_INSEE, GEOM, GEO_DV, GEO_DF, GEO_TEXTE, GEO_LIG_OFFSET_D, GEO_LIG_OFFSET_G, GEO_TYPE, GEO_NMN, GEO_DM, MODIFICATION) 
            VALUES( :old.objectid,
                :old.cla_inu,
                :old.geo_ref,
                :old.geo_insee,
                :old.geom,
                :old.geo_dv,
                :old.geo_df,
                :old.geo_texte,
                :old.geo_lig_offset_d,
                :old.geo_lig_offset_g,
                :old.geo_type,
                username,
                sysdate,
                1
            );
        END IF;
        IF DELETING THEN
            INSERT INTO GEO.TA_LIG_TOPO_G_LOG(FID_IDENTIFIANT, CLA_INU, GEO_REF, GEO_INSEE, GEOM, GEO_DV, GEO_DF, GEO_TEXTE, GEO_LIG_OFFSET_D, GEO_LIG_OFFSET_G, GEO_TYPE, GEO_NMN, GEO_DM, MODIFICATION) 
            VALUES( :old.objectid,
                :old.cla_inu,
                :old.geo_ref,
                :old.geo_insee,
                :old.geom,
                :old.geo_dv,
                :old.geo_df,
                :old.geo_texte,
                :old.geo_lig_offset_d,
                :old.geo_lig_offset_g,
                :old.geo_type,
                username,
                sysdate,
                0
            );
        END IF;

        EXCEPTION
            WHEN OTHERS THEN
                mail.sendmail('geotrigger@lillemetropole.fr',SQLERRM,'ERREUR TRIGGER - geo.TA_LIG_TOPO_G_LOG','bjacq@lillemetropole.fr', 'sysdig@lillemetropole.fr');
    END;