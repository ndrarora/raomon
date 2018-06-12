drop user omon;
create user omon identified by xxomonyy;
alter user omon default tablespace psdefault;
alter user omon temporary tablespace pstemp;
alter user omon temporary tablespace temp;
grant create session to omon;
grant select any table to omon;
grant SELECT_CATALOG_ROLE to omon;
