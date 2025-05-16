--1
Declare
vsql1 varchar2(200) :='Create table OUVRIERS
(Matricule number primary key,
Nom varchar(20),
prenom varchar(20),
PrixJr number,
Ref number references chantiers(reference))';
vsql2 varchar(200) :='create table chantiers(
Reference number primary key,
Lieu varchar(20),
dateDebut date, Duree integer,
NbrOuvrierAffectes number)';
BEGIN
Execute immediate(vsql2);
Execute immediate(vsql1);
END;
/
--2
CREATE OR REPLACE PROCEDURE
proc_insertion_chantier
(ref chantiers.reference%type,
lieu chantiers.lieu%type,
datedebut chantiers.datedebut%type,
duree chantiers.duree%type)
IS
BEGIN
insert into chantiers values (ref, lieu, datedebut,duree, null);
Exception
when dup_val_on_index then
dbms_output.put_line('chantier existant');
END;
/
--3
CREATE OR REPLACE PROCEDURE
proc_insertion_ouvrier
(Mat ouvriers.Matricule%type,
Nom ouvriers.nom%type,
Prenom ouvriers.prenom%type,
PrixJr ouvriers.prixjr%type,
Ref ouvriers.ref%type
)
IS
R chantiers.reference%type;
E exception;
BEGIN
select reference into R from chantiers 
where reference=ref;
if prixJr<10 then Raise E;
end if;
Insert into ouvriers values (Mat,nom,prenom,prixjr,ref);
Exception
when E then dbms_output.put_line('prixjr<10');
when no_data_found then 
dbms_output.put_line('chantier inexistant');
when dup_val_on_index then 
dbms_ouptut.put_line('ouvrier existant');
END;
/
--appel
declare

begin
proc_insertion_ouvrier(30,'test1','test', 30, 11);
proc_insertion_ouvrier(31,'test2','test', 31, 11);
proc_insertion_ouvrier(32,'test3','test', 32, 11);
end;
/
--4
CREATE OR REPLACE PROCEDURE
proc_insertion_ouvrier
(Mat in ouvriers.Matricule%type,
Nom in ouvriers.nom%type,
Prenom in ouvriers.prenom%type,
PrixJr in ouvriers.prixjr%type,
Ref in ouvriers.ref%type
nb out number
)
IS
R chantiers.reference%type;
E exception;
BEGIN
select reference into R from chantiers 
where reference=ref;
if prixJr<10 then Raise E;
end if;
Insert into ouvriers values (Mat,nom,prenom,prixjr,ref);
commit;
select count(*) into nb from ouvriers;

Exception
when E then dbms_output.put_line('prixjr<10');
when no_data_found then 
dbms_output.put_line('chantier inexistant');
when dup_val_on_index then 
dbms_ouptut.put_line('ouvrier existant');
END;
/
--5
create or replace function fn_fin_chantier (ref number)
return date
is
c number;
date_fin date;
begin
select count(*) into c from chantiers where reference = ref;
if c != 0 then
select datedebut+duree into date_fin from chantiers
where reference = ref;
return date_fin;
else
return sysdate;
end if;
exception
when no_data_found then
dbms_output.put_line('informations chantier manquants');
end;
/
OuBien
------
CREATE OR REPLACE FUNCTION
fn_fin_chantier (ref chantiers.reference%type)
return date
IS
date_fin date; 
BEGIN
select datedebut+duree into date_fin from chantiers where reference=ref;
return date_fin;

EXCEPTION
When no_data_found  then 
dbms_output.put_line('chantier n existe pas');
END;
/ 

--appel
select fn_fin_chantier(11) from dual;

--6
CREATE OR REPLACE PROCEDURE 
proc_liste_ouvriers
IS 
BEGIN
for i in (select * from chantiers ) loop
dbms_output.put_line('***** '||i.reference);
for j in (select * from ouvriers where ref=i.reference) loop
dbms_output.put_line('--- '||j.matricule);
end loop;
end loop;
END;
/
OuBien (solution avec curseur parametré)
------
CREATE OR REPLACE PROCEDURE 
proc_liste_ouvriers
IS 
cursor C_chantiers is select * from chantiers;
cursor C_ouvrier(r chantiers.reference%type) is select * from ouvrier where ref=r;
CR C_chantiers%TYPE;
CO C_ouvrier%TYPE;
BEGIN
for CR in C_chantiers loop
dbms_output.put_line('***** '||CR.reference);
for CO in C_ouvrier(CR.reference)  loop
dbms_output.put_line('--- '||j.matricule);
end loop;
end loop;
END;
/


--appel 
execute proc_liste_ouvriers

--PArtie 2 
--1
CREATE OR REPLACE TRIGGER Trig_message_avant
Before
INSERT ON ouvriers
BEGIN
dbms_output.put_line('Debut d''insertion');
END;
/

CREATE OR REPLACE TRIGGER Trig_message_apres
After
INSERT ON ouvriers
BEGIN
dbms_output.put_line('Fin d''insertion');
END;
/

--2
CREATE OR REPLACE TRIGGER Trig_messages_LMD
BEFORE 
insert or update or delete
ON CHANTIERS
BEGIN
if inserting then 
dbms_output.put_line('Insertion le '|| 
to_char(sysdate,'dd/mm/yyyy')||' à 
'||to_char(sysdate,'HH24')||'H');
elsif updating then 
dbms_output.put_line('Modification le '|| to_char(sysdate,'dd/mm/yyyy')||' à '||to_char(sysdate,'HH24')||'H');
else
dbms_output.put_line('Suppression le '|| to_char(sysdate,'dd/mm/yyyy')||' à '||to_char(sysdate,'HH24')||'H');
end if;
END;
/

--3
CREATE OR REPLACE TRIGGER Trig_nbrOuvriers 
AFTER 
INSERT OR DELETE on OUVRIERS
FOR EACH ROW
BEGIN
if inserting then
update chantiers set nbrOuvrierAffectes = 
nvl(nbrOuvrierAffectes,0) +1 where reference = :new.ref;
else
update chantiers set nbrOuvrierAffectes = 
nvl(nbrOuvrierAffectes,0) -1 where reference = :old.Ref;
end if;
END;
/
oubien
------
CREATE OR REPLACE TRIGGER Trig_nbrOuvriers 
AFTER 
INSERT OR DELETE on OUVRIERS
FOR EACH ROW
nbo number;
BEGIN
if inserting then
update chantiers set nbrOuvrierAffectes = 
nvl(nbrOuvrierAffectes,0) +1 where reference = :new.ref;
else
  select nbrOuvrierAffectes into nbo from chantiers where
  reference=:OLD.Ref;
  if nbo is not null then
update chantiers set nbrOuvrierAffectes = 
nbrOuvrierAffectes-1 where reference = :old.Ref;
end if;
end if;
END;
/

--4
create table historiques
(type_requete varchar(15),
date_operations date,
heure varchar(10),
utilisateur varchar(20)
);

--5
CREATE OR REPLACE TRIGGER trig_historique
After
insert or update or delete 
on chantiers
declare
operation varchar(15):='INSERT';
Begin
if updating then operation := 'UPDATE';
elsif deleting then operation :='DELETE';
end if;
insert into historiques values(
operation,sysdate, to_char(sysdate,'HH24:MI'),
USER);
end;
/
--6
CREATE OR REPLACE TRIGGER Trig_control 
BEFORE INSERT or update or delete 
on ouvriers
for each row
when  (TRIM(lower(to_char(sysdate,'day'))) in ('samedi','dimanche'))
BEGIN
raise_application_error(-20001,'vous n''avez pas le droit d''efectuer cette eperation');
end;
/
--OU:
create or replace trigger trig_control 
before insert or update or delete on OUVREIRS
begin
if (( inserting or updating or deleting ) AND 
(TRIM(to_char(sysdate, 'day' )) in ( 'dimanche', 'samedi'))) then
raise_application_error (-20002, 'acces interdit'); 
end if;
end;
/