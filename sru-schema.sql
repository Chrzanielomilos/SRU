--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.20
-- Dumped by pg_dump version 9.6.20

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: admin_update(); Type: FUNCTION; Schema: public; Owner: sru
--

CREATE FUNCTION public.admin_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
if
	NEW.password!=OLD.password AND (OLD.password_inner IS NULL OR NEW.password_inner=OLD.password_inner)
then
	INSERT INTO admins_history (
		admin_id,
		"login",
		"name",
		modified_by,
		modified_at,
		type_id,
		phone,
		jid,
		email,
		dormitory_id,
		address,
		active,
		active_to,
		password_changed
	) VALUES (
		OLD.id,
		OLD."login",
		OLD."name",
		OLD.modified_by,
		OLD.modified_at,
		OLD.type_id,
		OLD.phone,
		OLD.jid,
		OLD.email,
		OLD.dormitory_id,
		OLD.address,
		OLD.active,
		OLD.active_to,
		now()
	);
elsif
	NEW.password=OLD.password AND ((OLD.password_inner IS NULL AND NEW.password_inner IS NOT NULL) OR NEW.password_inner!=OLD.password_inner)
then
	INSERT INTO admins_history (
		admin_id,
		"login",
		"name",
		modified_by,
		modified_at,
		type_id,
		phone,
		jid,
		email,
		dormitory_id,
		address,
		active,
		active_to,
		password_inner_changed
	) VALUES (
		OLD.id,
		OLD."login",
		OLD."name",
		OLD.modified_by,
		OLD.modified_at,
		OLD.type_id,
		OLD.phone,
		OLD.jid,
		OLD.email,
		OLD.dormitory_id,
		OLD.address,
		OLD.active,
		OLD.active_to,
		now()
	);
elsif
	NEW.password!=OLD.password AND ((OLD.password_inner IS NULL AND NEW.password_inner IS NOT NULL) OR NEW.password_inner!=OLD.password_inner)
then
	INSERT INTO admins_history (
		admin_id,
		"login",
		"name",
		modified_by,
		modified_at,
		type_id,
		phone,
		jid,
		email,
		dormitory_id,
		address,
		active,
		active_to,
		password_changed,
		password_inner_changed
	) VALUES (
		OLD.id,
		OLD."login",
		OLD."name",
		OLD.modified_by,
		OLD.modified_at,
		OLD.type_id,
		OLD.phone,
		OLD.jid,
		OLD.email,
		OLD.dormitory_id,
		OLD.address,
		OLD.active,
		OLD.active_to,
		now(),
		now()
	);
elsif
	NEW."login"!=OLD."login" OR
	NEW."name"!=OLD."name" OR
	NEW.modified_by!=OLD.modified_by OR
	NEW.modified_at!=OLD.modified_at OR
	NEW.type_id!=OLD.type_id OR
	NEW.phone!=OLD.phone OR
	NEW.jid!=OLD.jid OR
	NEW.email!=OLD.email OR
	NEW.dormitory_id!=OLD.dormitory_id OR
	NEW.address!=OLD.address OR
	NEW.active!=OLD.active OR
	NEW.active_to!=OLD.active_to
then
	INSERT INTO admins_history (
		admin_id,
		"login",
		"name",
		modified_by,
		modified_at,
		type_id,
		phone,
		jid,
		email,
		dormitory_id,
		address,
		active,
		active_to
	) VALUES (
		OLD.id,
		OLD."login",
		OLD."name",
		OLD.modified_by,
		OLD.modified_at,
		OLD.type_id,
		OLD.phone,
		OLD.jid,
		OLD.email,
		OLD.dormitory_id,
		OLD.address,
		OLD.active,
		OLD.active_to
	);
end if;
return NEW;
END;$$;


ALTER FUNCTION public.admin_update() OWNER TO sru;

--
-- Name: FUNCTION admin_update(); Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON FUNCTION public.admin_update() IS 'archiwizacja informacji o adminie';


--
-- Name: computer_add(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.computer_add() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
	penalties_cursor CURSOR FOR
		SELECT id FROM penalties p WHERE p.user_id = NEW.user_id AND active = true AND type_id = 3;
	penalty penalties%ROWTYPE;
	computer_ban computers_bans%ROWTYPE;

BEGIN
IF NEW.banned = true THEN
	RETURN NEW;
END IF;
IF ('INSERT' = TG_OP OR ('UPDATE' = TG_OP AND NEW.active = true)) THEN
	OPEN penalties_cursor;
	LOOP
		FETCH penalties_cursor INTO penalty;
		EXIT WHEN NOT FOUND;
		SELECT id INTO computer_ban FROM computers_bans WHERE computer_id = NEW.id AND penalty_id = penalty.id;
		IF NOT FOUND THEN
			INSERT INTO computers_bans(computer_id, penalty_id, active) 
				VALUES (NEW.id, penalty.id, true);
		END IF;
	END LOOP;
	CLOSE penalties_cursor;
END IF;
RETURN NEW;
END;$$;


ALTER FUNCTION public.computer_add() OWNER TO postgres;

--
-- Name: FUNCTION computer_add(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.computer_add() IS 'naklada kare na nowy komputer, jesli uzytkownik jest zbanowany';


--
-- Name: computer_ban_computers(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.computer_ban_computers() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
IF ('INSERT' = TG_OP) THEN
	UPDATE computers
		SET banned = true, bans = bans + 1
		WHERE id = NEW.computer_id;
ELSIF ('UPDATE' = TG_OP AND OLD.active = true AND NEW.active = false AND
(SELECT count(id) AS count FROM computers_bans WHERE active AND computer_id = OLD.computer_id) < 1) THEN
	UPDATE computers
		SET banned = false
		WHERE id = OLD.computer_id;
END IF;
RETURN NEW;
END;$$;


ALTER FUNCTION public.computer_ban_computers() OWNER TO postgres;

--
-- Name: FUNCTION computer_ban_computers(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.computer_ban_computers() IS 'modyfikuje komputery, ktorych dotyczy kara';


--
-- Name: computer_counters(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.computer_counters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	change INT := 0; -- 2 = dodaj w nowym, 1 = usun w starym, 3 = usun w starym i dodaj w nowym
BEGIN
IF ('INSERT' = TG_OP AND NEW.active) THEN
	change := 2;
ELSIF ('UPDATE' = TG_OP) THEN
	IF (OLD.location_id <> NEW.location_id) THEN
		change := 3;
	END IF;
	IF (OLD.active = false AND NEW.active = true) THEN
		change := 2;
	ELSIF (OLD.active = true AND NEW.active = false) THEN
		change := 1;
	ELSIF (OLD.active = false AND NEW.active = false) THEN
		change := 0;
	END IF;
ELSIF ('DELETE' = TG_OP AND OLD.active) THEN
	change := 1;
END IF;
IF (1 = change OR 3 = change) THEN
	UPDATE locations
		SET computers_count = computers_count - 1
		WHERE id = OLD.location_id;
END IF;
IF (2 = change OR 3 = change) THEN
	UPDATE locations
		SET computers_count = computers_count + 1
		WHERE id = NEW.location_id;
END IF;
RETURN NEW;
END;$$;


ALTER FUNCTION public.computer_counters() OWNER TO postgres;

--
-- Name: FUNCTION computer_counters(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.computer_counters() IS 'modyfikuje liczniki liczace komputery';


--
-- Name: computer_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.computer_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
if
	OLD.host!=NEW.host OR
	OLD.mac!=NEW.mac OR
	OLD.ipv4!=NEW.ipv4 OR
	OLD.user_id!=NEW.user_id OR
	OLD.location_id!=NEW.location_id OR
	OLD.avail_to!=NEW.avail_to OR
	(OLD.avail_to IS NULL AND NEW.avail_to IS NOT NULL) OR
	(OLD.avail_to IS NOT NULL AND NEW.avail_to IS NULL) OR
	OLD.comment!=NEW.comment OR
	OLD.can_admin!=NEW.can_admin OR
	OLD.active!=NEW.active OR
	OLD.type_id!=NEW.type_id OR
	OLD.exadmin!=NEW.exadmin OR
	OLD.carer_id!=NEW.carer_id OR
	(OLD.carer_id IS NULL AND NEW.carer_id IS NOT NULL) OR
	(OLD.carer_id IS NOT NULL AND NEW.carer_id IS NULL) OR
	OLD.master_host_id!=NEW.master_host_id OR
	(OLD.master_host_id IS NULL AND NEW.master_host_id IS NOT NULL) OR
	(OLD.master_host_id IS NOT NULL AND NEW.master_host_id IS NULL) OR
	OLD.auto_deactivation!=NEW.auto_deactivation OR
	OLD.device_model_id!=NEW.device_model_id
then
	INSERT INTO computers_history (
		computer_id,
		host,
		mac,
		ipv4,
		user_id,
		location_id,
		avail_to,
		modified_by,
		modified_at,
		comment,
		can_admin,
		active,
		type_id,
		exadmin,
		carer_id,
		master_host_id,
		auto_deactivation,
		device_model_id
	) VALUES (
		OLD.id,
		OLD.host,
		OLD.mac,
		OLD.ipv4,
		OLD.user_id,
		OLD.location_id,
		OLD.avail_to,
		OLD.modified_by,
		OLD.modified_at,
		OLD.comment,
		OLD.can_admin,
		OLD.active,
		OLD.type_id,
		OLD.exadmin,
		OLD.carer_id,
		OLD.master_host_id,
		OLD.auto_deactivation,
		OLD.device_model_id
	);
end if;
return NEW;
END;$$;


ALTER FUNCTION public.computer_update() OWNER TO postgres;

--
-- Name: FUNCTION computer_update(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.computer_update() IS 'archiwizacja danych komputera';


--
-- Name: computers_add_domain_name(); Type: FUNCTION; Schema: public; Owner: sru
--

CREATE FUNCTION public.computers_add_domain_name() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	NEW.domain_name = NEW.host || '.' || (SELECT domain_suffix FROM vlans v, ipv4s i WHERE v.id = i.vlan AND i.ip = NEW.ipv4);
return NEW;
END;$$;


ALTER FUNCTION public.computers_add_domain_name() OWNER TO sru;

--
-- Name: FUNCTION computers_add_domain_name(); Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON FUNCTION public.computers_add_domain_name() IS 'ustawienie nazwy domenowej';


--
-- Name: computers_change_location(); Type: FUNCTION; Schema: public; Owner: sru
--

CREATE FUNCTION public.computers_change_location() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
IF
	NEW.location_id!=OLD.location_id
THEN
	UPDATE computers SET location_id = NEW.location_id, modified_by = NEW.modified_by, modified_at = NEW.modified_at WHERE master_host_id = NEW.id;
END IF;
return NEW;
END;$$;


ALTER FUNCTION public.computers_change_location() OWNER TO sru;

--
-- Name: FUNCTION computers_change_location(); Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON FUNCTION public.computers_change_location() IS 'aktualziacja lokalizacji maszyn wirtualnych interfejsow';


--
-- Name: computers_seen_update(macaddr, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.computers_seen_update(macaddr, timestamp without time zone) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
	BEGIN
		UPDATE computers SET last_seen = $2 WHERE mac = $1 and active = true;
		RETURN true;
	END;
$_$;


ALTER FUNCTION public.computers_seen_update(macaddr, timestamp without time zone) OWNER TO postgres;

--
-- Name: computers_set_domain_name(); Type: FUNCTION; Schema: public; Owner: sru
--

CREATE FUNCTION public.computers_set_domain_name() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	IF
		NEW.host!=OLD.host OR
		OLD.ipv4!=NEW.ipv4
	THEN
		NEW.domain_name = NEW.host || '.' || (SELECT domain_suffix FROM vlans v, ipv4s i WHERE v.id = i.vlan AND i.ip = NEW.ipv4);
	END IF;
return NEW;
END;$$;


ALTER FUNCTION public.computers_set_domain_name() OWNER TO sru;

--
-- Name: FUNCTION computers_set_domain_name(); Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON FUNCTION public.computers_set_domain_name() IS 'aktualizacja nazwy domenowej';


--
-- Name: device_update(); Type: FUNCTION; Schema: public; Owner: sru
--

CREATE FUNCTION public.device_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
if
	NEW.modified_by!=OLD.modified_by OR
	NEW.modified_at!=OLD.modified_at OR
	NEW.location_id!=OLD.location_id OR
	NEW.device_model_id!=OLD.device_model_id OR
	NEW.inoperational!=OLD.inoperational OR
	NEW.used!=OLD.used OR
	NEW.comment!=OLD.comment OR
	(OLD.comment IS NOT NULL AND NEW.comment IS NULL) OR
	(OLD.comment IS NULL AND NEW.comment IS NOT NULL)
then
	INSERT INTO devices_history (
		device_id,
		modified_by,
		modified_at,
		location_id,
		device_model_id,
		inoperational,
		used,
		comment
	) VALUES (
		OLD.id,
		OLD.modified_by,
		OLD.modified_at,
		OLD.location_id,
		OLD.device_model_id,
		OLD.inoperational,
		OLD.used,
		OLD.comment
	);
end if;
return NEW;
END;$$;


ALTER FUNCTION public.device_update() OWNER TO sru;

--
-- Name: FUNCTION device_update(); Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON FUNCTION public.device_update() IS 'archiwizacja pozostalych urzadzen i sprzetow';


--
-- Name: inventory_card_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.inventory_card_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
if
	NEW.dormitory_id!=OLD.dormitory_id OR
	NEW.serial_no!=OLD.serial_no OR
	NEW.inventory_no!=OLD.inventory_no OR
	(OLD.inventory_no IS NULL AND NEW.inventory_no IS NOT NULL) OR
	(OLD.inventory_no IS NOT NULL AND NEW.inventory_no IS NULL) OR
	NEW.received!=OLD.received OR
	(OLD.received IS NULL AND NEW.received IS NOT NULL) OR
	(OLD.received IS NOT NULL AND NEW.received IS NULL) OR
	NEW.comment!=OLD.comment OR
	(OLD.comment IS NOT NULL AND NEW.comment IS NULL) OR
	(OLD.comment IS NULL AND NEW.comment IS NOT NULL)
then
	INSERT INTO inventory_cards_history (
		inventory_card_id,
		modified_by,
		modified_at,
		dormitory_id,
		serial_no,
		inventory_no,
		received,
		comment
	) VALUES (
		OLD.id,
		OLD.modified_by,
		OLD.modified_at,
		OLD.dormitory_id,
		OLD.serial_no,
		OLD.inventory_no,
		OLD.received,
		OLD.comment
	);
end if;
return NEW;
END;$$;


ALTER FUNCTION public.inventory_card_update() OWNER TO postgres;

--
-- Name: FUNCTION inventory_card_update(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.inventory_card_update() IS 'archiwizacja karty wyposazenia';


--
-- Name: ipv4_counters(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ipv4_counters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
IF ('INSERT' = TG_OP) THEN
	IF (NEW.dormitory_id IS NOT NULL) THEN
		UPDATE dormitories
			SET computers_max = computers_max + 1
			WHERE id = NEW.dormitory_id;
	END IF;
ELSIF ('UPDATE' = TG_OP) THEN
	IF (NEW.dormitory_id<>OLD.dormitory_id) THEN
		IF (OLD.dormitory_id IS NOT NULL) THEN
			UPDATE dormitories
				SET computers_max = computers_max - 1
				WHERE id = OLD.dormitory_id;
		END IF;
		IF (NEW.dormitory_id IS NOT NULL) THEN
			UPDATE dormitories
				SET computers_max = computers_max + 1
				WHERE id = NEW.dormitory_id;
		END IF;
	END IF;
ELSIF ('DELETE' = TG_OP) THEN
	IF (OLD.dormitory_id IS NOT NULL) THEN
		UPDATE dormitories
			SET computers_max = computers_max - 1
			WHERE id = OLD.dormitory_id;
	END IF;
END IF;
RETURN NEW;
END;$$;


ALTER FUNCTION public.ipv4_counters() OWNER TO postgres;

--
-- Name: FUNCTION ipv4_counters(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.ipv4_counters() IS 'modyfikuje liczniki ip-kow';


--
-- Name: location_counters(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.location_counters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
IF ('UPDATE' = TG_OP) THEN
	IF (OLD.computers_count <> NEW.computers_count) THEN
		UPDATE dormitories
			SET computers_count = computers_count + NEW.computers_count - OLD.computers_count
			WHERE id = NEW.dormitory_id;
	END IF;
	IF (OLD.users_count <> NEW.users_count) THEN
		UPDATE dormitories
			SET users_count = users_count + NEW.users_count - OLD.users_count
			WHERE id = NEW.dormitory_id;
	END IF;
	IF (OLD.users_max <> NEW.users_max) THEN
		UPDATE dormitories
			SET users_max = users_max + NEW.users_max - OLD.users_max
			WHERE id = NEW.dormitory_id;
	END IF;
	IF (OLD.dormitory_id <> NEW.dormitory_id) THEN
		UPDATE dormitories
			SET users_max = users_max - NEW.users_max -- new.users_max, bo nieco wyzej juz zmodyfikowalismy users_max dla danego akademika
			WHERE id = OLD.dormitory_id;
		UPDATE dormitories
			SET users_max = users_max + NEW.users_max
			WHERE id = NEW.dormitory_id;
	END IF;
ELSIF ('INSERT' = TG_OP) THEN
	IF (NEW.users_max<>0) THEN
		UPDATE dormitories
			SET users_max = users_max + NEW.users_max
			WHERE id = NEW.dormitory_id;
	END IF;
ELSIF ('DELETE' = TG_OP) THEN
	IF (OLD.users_max<>0) THEN
		UPDATE dormitories
			SET users_max = users_max - OLD.users_max
			WHERE id = OLD.dormitory_id;
	END IF;
END IF;
RETURN NEW;
END;$$;


ALTER FUNCTION public.location_counters() OWNER TO postgres;

--
-- Name: FUNCTION location_counters(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.location_counters() IS 'modyfikuje liczniki uzytkownikow i komputerow';


--
-- Name: location_update(); Type: FUNCTION; Schema: public; Owner: sru
--

CREATE FUNCTION public.location_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
if
	NEW."comment"!=OLD."comment" OR
	NEW.users_max!=OLD.users_max OR
	NEW.type_id!=OLD.type_id
then
	INSERT INTO locations_history (
		location_id,
		"comment",
		users_max,
		type_id,
		modified_by,
		modified_at
	) VALUES (
		OLD.id,
		OLD."comment",
		OLD.users_max,
		OLD.type_id,
		OLD.modified_by,
		OLD.modified_at
	);
end if;
return NEW;
END;$$;


ALTER FUNCTION public.location_update() OWNER TO sru;

--
-- Name: FUNCTION location_update(); Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON FUNCTION public.location_update() IS 'archiwizacja informacji o lokacji';


--
-- Name: next_free_id_from(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.next_free_id_from(table_name text) RETURNS bigint
    LANGUAGE plpgsql STRICT
    AS $$
DECLARE
  next_id BIGINT;
BEGIN
  execute 'select rn from (select id, row_number() over (order by id) as rn from ' || quote_ident(table_name) || ') as T where id > rn limit 1' into next_id;
  if next_id is null then
    execute 'select COALESCE(max(id), 0) + 1 from ' || quote_ident(table_name) into next_id;
  end if;
  return next_id;
END;
$$;


ALTER FUNCTION public.next_free_id_from(table_name text) OWNER TO postgres;

--
-- Name: penalty_computers_bans(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.penalty_computers_bans() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
IF ('UPDATE' = TG_OP) THEN
IF (OLD.active = true AND NEW.active = false) THEN
	 UPDATE computers_bans
		SET active = false
		WHERE penalty_id = OLD.id;
END IF;
END IF;
RETURN NEW;
END;$$;


ALTER FUNCTION public.penalty_computers_bans() OWNER TO postgres;

--
-- Name: FUNCTION penalty_computers_bans(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.penalty_computers_bans() IS 'modyfikuje bany na komputery';


--
-- Name: penalty_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.penalty_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
if
	NEW.end_at!=OLD.end_at OR
	NEW."comment"!=OLD."comment" OR
	NEW.modified_by!=OLD.modified_by OR
	NEW.reason!=OLD.reason OR
	NEW.modified_at!=OLD.modified_at OR
	NEW.amnesty_after!=OLD.amnesty_after
then
	INSERT INTO penalties_history (
		penalty_id,
		end_at,
		comment,
		modified_by,
		reason,
		modified_at,
		amnesty_after
	) VALUES (
		OLD.id,
		OLD.end_at,
		OLD.comment,
		OLD.modified_by,
		OLD.reason,
		OLD.modified_at,
		OLD.amnesty_after
	);
end if;
return NEW;
END;$$;


ALTER FUNCTION public.penalty_update() OWNER TO postgres;

--
-- Name: FUNCTION penalty_update(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.penalty_update() IS 'archiwizacja informacji o karze';


--
-- Name: penalty_users(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.penalty_users() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
IF ('INSERT' = TG_OP) THEN
	IF NEW.type_id<>1 THEN	-- nie ostrzezenie
		UPDATE users
			SET banned = true, bans = bans + 1
			WHERE id = NEW.user_id;
	ELSE
		UPDATE users
			SET bans = bans + 1
			WHERE id = NEW.user_id;
	END IF;
ELSIF ('UPDATE' = TG_OP) THEN
	IF (OLD.active=true AND NEW.active = false AND (SELECT COUNT(*) from penalties where active='true' and type_id<>1 and user_id = old.user_id) = 0) THEN
		UPDATE users
			SET banned = false
			WHERE users.id = old.user_id;
	END IF;
END IF;
RETURN NEW;
END;$$;


ALTER FUNCTION public.penalty_users() OWNER TO postgres;

--
-- Name: FUNCTION penalty_users(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.penalty_users() IS 'modyfikuje dane uzytkownika';


--
-- Name: remove_bans(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.remove_bans() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
        updated INT;
BEGIN
        UPDATE penalties SET active = 'false' WHERE active = 'true' and end_at < now();

        GET DIAGNOSTICS updated = ROW_COUNT;
        RETURN updated;
END;
$$;


ALTER FUNCTION public.remove_bans() OWNER TO postgres;

--
-- Name: switch_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.switch_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
if
	NEW.location_id!=OLD.location_id OR
	NEW.model!=OLD.model OR
	NEW.inoperational!=OLD.inoperational OR
	NEW.hierarchy_no!=OLD.hierarchy_no OR
	(OLD.hierarchy_no IS NULL AND NEW.hierarchy_no IS NOT NULL) OR
	(OLD.hierarchy_no IS NOT NULL AND NEW.hierarchy_no IS NULL) OR
	NEW.ipv4!=OLD.ipv4 OR
	(OLD.ipv4 IS NULL AND NEW.ipv4 IS NOT NULL) OR
	(OLD.ipv4 IS NOT NULL AND NEW.ipv4 IS NULL) OR
	NEW.comment!=OLD.comment OR
	(OLD.comment IS NOT NULL AND NEW.comment IS NULL) OR
	(OLD.comment IS NULL AND NEW.comment IS NOT NULL)
then
	INSERT INTO switches_history (
		switch_id,
		modified_by,
		modified_at,
		location_id,
		model,
		inoperational,
		hierarchy_no,
		ipv4,
		comment
	) VALUES (
		OLD.id,
		OLD.modified_by,
		OLD.modified_at,
		OLD.location_id,
		OLD.model,
		OLD.inoperational,
		OLD.hierarchy_no,
		OLD.ipv4,
		OLD.comment
	);
end if;
return NEW;
END;$$;


ALTER FUNCTION public.switch_update() OWNER TO postgres;

--
-- Name: FUNCTION switch_update(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.switch_update() IS 'archiwizacja switcha';


--
-- Name: user_computers(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_computers() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
IF ('UPDATE' = TG_OP) THEN
IF (OLD.active=true AND NEW.active=false) THEN
	UPDATE computers
		SET	active = false,
			can_admin = false,
			modified_by = new.modified_by,
			modified_at = new.modified_at,
			avail_to = new.modified_at
		WHERE user_id = NEW.id AND active = true;

END IF;
END IF;
RETURN NEW;
END;$$;


ALTER FUNCTION public.user_computers() OWNER TO postgres;

--
-- Name: FUNCTION user_computers(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.user_computers() IS 'zmienia dane komputerow';


--
-- Name: user_counters(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_counters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	change INT := 0; -- 1 = usun ze starego, 2 = dodaj do nowego, 3 = obie akcje
BEGIN
IF ('INSERT' = TG_OP) THEN
	IF (NEW.active) THEN
		change := 2;
	END IF;
ELSIF ('UPDATE' = TG_OP) THEN
	IF (OLD.location_id <> NEW.location_id) THEN
		change := 3;
	END IF;
	IF (OLD.active = false AND NEW.active = true) THEN
		change := 2;
	ELSIF (OLD.active = true AND NEW.active = false) THEN
		change := 1;
	ELSIF (OLD.active = false AND NEW.active = false) THEN
		change := 0;
	END IF;
ELSIF ('DELETE' = TG_OP) THEN
	IF (OLD.active) THEN
		UPDATE locations
			SET users_count = users_count - 1
			WHERE id = OLD.location_id;
	END IF;
END IF;
IF (1 = change OR 3 = change) THEN
	UPDATE locations
		SET users_count = users_count - 1
		WHERE id = OLD.location_id;
END IF;
IF (2 = change OR 3 = change) THEN
	UPDATE locations
		SET users_count = users_count + 1
		WHERE id = NEW.location_id;
END IF;
RETURN NEW;
END;$$;


ALTER FUNCTION public.user_counters() OWNER TO postgres;

--
-- Name: FUNCTION user_counters(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.user_counters() IS 'modyfikuje liczniki liczace uzytkownikow';


--
-- Name: user_update(); Type: FUNCTION; Schema: public; Owner: sru
--

CREATE FUNCTION public.user_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
if
	NEW.password!=OLD.password
then
	INSERT INTO users_history (
		user_id,
		name,
		surname,
		login,
		email,
		faculty_id,
		study_year_id,
		location_id,
		modified_by,
		modified_at,
		comment,
		active,
		referral_start,
		referral_end,
		registry_no,
		update_needed,
		change_password_needed,
		password_changed,
		lang,
		type_id,
		nationality,
		address,
		birth_date,
		birth_place,
		pesel,
		document_type,
		document_number,
		user_phone_number,
		guardian_phone_number,
		sex,
		last_location_change,
		comment_skos,
		over_limit,
		to_deactivate
	) VALUES (
		OLD.id,
		OLD.name,
		OLD.surname,
		OLD.login,
		OLD.email,
		OLD.faculty_id,
		OLD.study_year_id,
		OLD.location_id,
		OLD.modified_by,
		OLD.modified_at,
		OLD.comment,
		OLD.active,
		OLD.referral_start,
		OLD.referral_end,
		OLD.registry_no,
		OLD.update_needed,
		OLD.change_password_needed,
		now(),
		OLD.lang,
		OLD.type_id,
		OLD.nationality,
		OLD.address,
		OLD.birth_date,
		OLD.birth_place,
		OLD.pesel,
		OLD.document_type,
		OLD.document_number,
		OLD.user_phone_number,
		OLD.guardian_phone_number,
		OLD.sex,
		OLD.last_location_change,
		OLD.comment_skos,
		OLD.over_limit,
		OLD.to_deactivate
	);
elsif
	NEW.name!=OLD.name OR
	NEW.surname!=OLD.surname OR
	NEW.login!=OLD.login OR
	NEW.email!=OLD.email OR
	(OLD.email IS NULL AND NEW.email IS NOT NULL) OR
	NEW.faculty_id!=OLD.faculty_id OR
	NEW.study_year_id!=OLD.study_year_id OR
	NEW.location_id!=OLD.location_id OR
	NEW.comment!=OLD.comment OR
	NEW.active!=OLD.active OR
	NEW.referral_start!=OLD.referral_start OR
	(OLD.referral_start IS NULL AND NEW.referral_start IS NOT NULL) OR
	(OLD.referral_start IS NOT NULL AND NEW.referral_start IS NULL) OR
	NEW.referral_end!=OLD.referral_end OR
	(OLD.referral_end IS NULL AND NEW.referral_end IS NOT NULL) OR
	(OLD.referral_end IS NOT NULL AND NEW.referral_end IS NULL) OR
	NEW.registry_no!=OLD.registry_no OR
	(OLD.registry_no IS NULL AND NEW.registry_no IS NOT NULL) OR
	(OLD.registry_no IS NOT NULL AND NEW.registry_no IS NULL) OR
	NEW.update_needed!=OLD.update_needed OR
	NEW.change_password_needed!=OLD.change_password_needed OR
	NEW.lang!=OLD.lang OR
	NEW.type_id!=OLD.type_id OR
	NEW.nationality!=OLD.nationality OR
	(OLD.nationality IS NULL AND NEW.nationality IS NOT NULL) OR
	(OLD.nationality IS NOT NULL AND NEW.nationality IS NULL) OR
	NEW.address!=OLD.address OR
	(OLD.address IS NULL AND NEW.address IS NOT NULL) OR
	(OLD.address IS NOT NULL AND NEW.address IS NULL) OR
	NEW.birth_date!=OLD.birth_date OR
	(OLD.birth_date IS NULL AND NEW.birth_date IS NOT NULL) OR
	(OLD.birth_date IS NOT NULL AND NEW.birth_date IS NULL) OR
	NEW.birth_place!=OLD.birth_place OR
	(OLD.birth_place IS NULL AND NEW.birth_place IS NOT NULL) OR
	(OLD.birth_place IS NOT NULL AND NEW.birth_place IS NULL) OR
	NEW.pesel!=OLD.pesel OR
	(OLD.pesel IS NULL AND NEW.pesel IS NOT NULL) OR
	(OLD.pesel IS NOT NULL AND NEW.pesel IS NULL) OR
	NEW.document_type!=OLD.document_type OR
	NEW.document_number!=OLD.document_number OR
	(OLD.document_number IS NULL AND NEW.document_number IS NOT NULL) OR
	(OLD.document_number IS NOT NULL AND NEW.document_number IS NULL) OR
	NEW.user_phone_number!=OLD.user_phone_number OR
	(OLD.user_phone_number IS NULL AND NEW.user_phone_number IS NOT NULL) OR
	(OLD.user_phone_number IS NOT NULL AND NEW.user_phone_number IS NULL) OR
	NEW.guardian_phone_number!=OLD.guardian_phone_number OR
	(OLD.guardian_phone_number IS NULL AND NEW.guardian_phone_number IS NOT NULL) OR
	(OLD.guardian_phone_number IS NOT NULL AND NEW.guardian_phone_number IS NULL) OR
	NEW.sex!=OLD.sex OR
	NEW.last_location_change!=OLD.last_location_change OR
	(OLD.last_location_change IS NULL AND NEW.last_location_change IS NOT NULL) OR
	NEW.comment_skos!=OLD.comment_skos OR
	NEW.over_limit!=OLD.over_limit OR
	NEW.to_deactivate!=OLD.to_deactivate
then
	INSERT INTO users_history (
		user_id,
		name,
		surname,
		login,
		email,
		faculty_id,
		study_year_id,
		location_id,
		modified_by,
		modified_at,
		comment,
		active,
		referral_start,
		referral_end,
		registry_no,
		update_needed,
		change_password_needed,
		lang,
		type_id,
		nationality,
		address,
		birth_date,
		birth_place,
		pesel,
		document_type,
		document_number,
		user_phone_number,
		guardian_phone_number,
		sex,
		last_location_change,
		comment_skos,
		over_limit,
		to_deactivate
	) VALUES (
		OLD.id,
		OLD.name,
		OLD.surname,
		OLD.login,
		OLD.email,
		OLD.faculty_id,
		OLD.study_year_id,
		OLD.location_id,
		OLD.modified_by,
		OLD.modified_at,
		OLD.comment,
		OLD.active,
		OLD.referral_start,
		OLD.referral_end,
		OLD.registry_no,
		OLD.update_needed,
		OLD.change_password_needed,
		OLD.lang,
		OLD.type_id,
		OLD.nationality,
		OLD.address,
		OLD.birth_date,
		OLD.birth_place,
		OLD.pesel,
		OLD.document_type,
		OLD.document_number,
		OLD.user_phone_number,
		OLD.guardian_phone_number,
		OLD.sex,
		OLD.last_location_change,
		OLD.comment_skos,
		OLD.over_limit,
		OLD.to_deactivate
	);
end if;
return NEW;
END;$$;


ALTER FUNCTION public.user_update() OWNER TO sru;

--
-- Name: FUNCTION user_update(); Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON FUNCTION public.user_update() IS 'archiwizacja danych uzytkownika';


--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admins_id_seq OWNER TO sru;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: admins; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.admins (
    id bigint DEFAULT nextval('public.admins_id_seq'::regclass) NOT NULL,
    login character varying NOT NULL,
    password character(60) NOT NULL,
    last_login_at timestamp with time zone,
    last_login_ip inet,
    name character varying(255) NOT NULL,
    type_id smallint DEFAULT 1 NOT NULL,
    phone character varying(50) DEFAULT ''::character varying NOT NULL,
    jid character varying(100) DEFAULT ''::character varying NOT NULL,
    email character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    dormitory_id bigint,
    address character varying(255) DEFAULT ''::character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    active_to timestamp with time zone,
    last_inv_login_at timestamp with time zone,
    last_inv_login_ip inet,
    modified_by bigint,
    modified_at timestamp with time zone DEFAULT now(),
    last_psw_change timestamp with time zone,
    password_md5 character(32),
    password_blow character(60),
    password_inner character(32),
    last_psw_inner_change timestamp with time zone,
    bad_logins smallint DEFAULT 0 NOT NULL,
    wifi_password character varying DEFAULT upper(substr(md5((random())::text), 0, 11)) NOT NULL
);


ALTER TABLE public.admins OWNER TO sru;

--
-- Name: TABLE admins; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.admins IS 'administratorzy';


--
-- Name: COLUMN admins.login; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.login IS 'login';


--
-- Name: COLUMN admins.password; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.password IS 'haslo zakodowane blowfish';


--
-- Name: COLUMN admins.last_login_at; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.last_login_at IS 'czas ostatniego logowania';


--
-- Name: COLUMN admins.last_login_ip; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.last_login_ip IS 'ip, z ktorego ostatnio sie logowal';


--
-- Name: COLUMN admins.name; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.name IS 'nazwa ekranowa - imie-ksywka-nazwisko albo nazwa bota itp.';


--
-- Name: COLUMN admins.type_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.type_id IS 'typ administratora: lokalny, osiedlowy, centralny, bot';


--
-- Name: COLUMN admins.phone; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.phone IS 'telefon prywatny';


--
-- Name: COLUMN admins.jid; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.jid IS 'jabber id';


--
-- Name: COLUMN admins.email; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.email IS '"oficjalny" email do administratora';


--
-- Name: COLUMN admins.created_at; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.created_at IS 'czas utworzenia konta';


--
-- Name: COLUMN admins.dormitory_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.dormitory_id IS 'akademik, nie dotyczy botow i centralnych';


--
-- Name: COLUMN admins.address; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.address IS 'gdzie mieszka administrator';


--
-- Name: COLUMN admins.active; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.active IS 'czy konto jest aktywne?';


--
-- Name: COLUMN admins.password_md5; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.password_md5 IS 'backup hasla w MD5';


--
-- Name: COLUMN admins.password_blow; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.password_blow IS 'backup hasla w blowfish';


--
-- Name: COLUMN admins.password_inner; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.admins.password_inner IS 'haslo zakodowane MD5';


--
-- Name: admins_dormitories_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.admins_dormitories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admins_dormitories_id_seq OWNER TO sru;

--
-- Name: admins_dormitories; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.admins_dormitories (
    id bigint DEFAULT nextval('public.admins_dormitories_id_seq'::regclass) NOT NULL,
    admin bigint,
    dormitory bigint
);


ALTER TABLE public.admins_dormitories OWNER TO sru;

--
-- Name: TABLE admins_dormitories; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.admins_dormitories IS 'Przypisania adminów do wielu akademików';


--
-- Name: admins_history; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.admins_history (
    id bigint NOT NULL,
    admin_id bigint NOT NULL,
    login character varying NOT NULL,
    name character varying(255) NOT NULL,
    type_id smallint DEFAULT 1 NOT NULL,
    phone character varying(50) DEFAULT ''::character varying NOT NULL,
    jid character varying(100) DEFAULT ''::character varying NOT NULL,
    email character varying(100) NOT NULL,
    dormitory_id bigint,
    address character varying(255) DEFAULT ''::character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    active_to timestamp with time zone,
    modified_by bigint,
    modified_at timestamp with time zone DEFAULT now(),
    password_changed timestamp with time zone,
    password_inner_changed timestamp with time zone
);


ALTER TABLE public.admins_history OWNER TO sru;

--
-- Name: TABLE admins_history; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.admins_history IS 'historia adminow';


--
-- Name: admins_history_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.admins_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admins_history_id_seq OWNER TO sru;

--
-- Name: admins_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.admins_history_id_seq OWNED BY public.admins_history.id;


--
-- Name: bans_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.bans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bans_id_seq OWNER TO sru;

--
-- Name: campuses; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.campuses (
    id integer NOT NULL,
    name character varying(20) NOT NULL
);


ALTER TABLE public.campuses OWNER TO sru;

--
-- Name: campuses_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.campuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campuses_id_seq OWNER TO sru;

--
-- Name: campuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.campuses_id_seq OWNED BY public.campuses.id;


--
-- Name: computers_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.computers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.computers_id_seq OWNER TO sru;

--
-- Name: computers; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.computers (
    id bigint DEFAULT nextval('public.computers_id_seq'::regclass) NOT NULL,
    host character varying(50) NOT NULL,
    mac macaddr NOT NULL,
    ipv4 inet NOT NULL,
    user_id bigint,
    location_id bigint NOT NULL,
    avail_to timestamp with time zone,
    modified_by bigint,
    modified_at timestamp with time zone DEFAULT now() NOT NULL,
    comment text DEFAULT ''::text NOT NULL,
    active boolean DEFAULT true NOT NULL,
    type_id smallint DEFAULT 1 NOT NULL,
    bans integer DEFAULT 0 NOT NULL,
    can_admin boolean DEFAULT false NOT NULL,
    banned boolean DEFAULT false NOT NULL,
    last_seen timestamp with time zone,
    last_activated timestamp with time zone DEFAULT now() NOT NULL,
    exadmin boolean DEFAULT false NOT NULL,
    carer_id bigint,
    master_host_id bigint,
    auto_deactivation boolean DEFAULT true NOT NULL,
    inventory_card_id bigint,
    device_model_id bigint,
    domain_name character varying(70) NOT NULL,
    CONSTRAINT computers_device_model_id_chk CHECK ((((type_id <> 41) AND (type_id <> 43)) OR (device_model_id IS NOT NULL)))
);


ALTER TABLE public.computers OWNER TO sru;

--
-- Name: TABLE computers; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.computers IS 'komputery';


--
-- Name: COLUMN computers.host; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers.host IS 'nazwa hosta';


--
-- Name: COLUMN computers.mac; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers.mac IS 'adres mac karty sieciowej';


--
-- Name: COLUMN computers.ipv4; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers.ipv4 IS 'adres ip';


--
-- Name: COLUMN computers.user_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers.user_id IS 'uzytkownik, do ktorego nalezy ten komputer';


--
-- Name: COLUMN computers.location_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers.location_id IS 'pokoj';


--
-- Name: COLUMN computers.avail_to; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers.avail_to IS 'do kiedy jest wazna rejestracja';


--
-- Name: COLUMN computers.modified_by; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers.modified_by IS 'kto wprowadzil te dane';


--
-- Name: COLUMN computers.modified_at; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers.modified_at IS 'czas powstania tej wersji';


--
-- Name: COLUMN computers.comment; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers.comment IS 'komentarz';


--
-- Name: COLUMN computers.active; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers.active IS 'czy komputer ma wazna rejestracje';


--
-- Name: COLUMN computers.type_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers.type_id IS 'typ komputera: student, administracja, organizacja, serwer itd.';


--
-- Name: COLUMN computers.bans; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers.bans IS 'licznik banow';


--
-- Name: COLUMN computers.can_admin; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers.can_admin IS 'komputer nalezy do administratora';


--
-- Name: COLUMN computers.banned; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers.banned IS 'czy komputer jest aktualnie zabanowany?';


--
-- Name: computers_aliases_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.computers_aliases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.computers_aliases_id_seq OWNER TO sru;

--
-- Name: computers_aliases; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.computers_aliases (
    id bigint DEFAULT nextval('public.computers_aliases_id_seq'::regclass) NOT NULL,
    computer_id bigint NOT NULL,
    host character varying(50) NOT NULL,
    domain_name character varying(70) NOT NULL,
    record_type smallint DEFAULT 1 NOT NULL,
    value character varying(127),
    avail_to timestamp with time zone
);


ALTER TABLE public.computers_aliases OWNER TO sru;

--
-- Name: COLUMN computers_aliases.computer_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_aliases.computer_id IS 'ktory komputer';


--
-- Name: COLUMN computers_aliases.host; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_aliases.host IS 'alias';


--
-- Name: COLUMN computers_aliases.record_type; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_aliases.record_type IS 'typ rekordu';


--
-- Name: COLUMN computers_aliases.value; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_aliases.value IS 'opcjonalna wartosc rekordu rekordu';


--
-- Name: COLUMN computers_aliases.avail_to; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_aliases.avail_to IS 'opcjonalna data usuniecia rekordu';


--
-- Name: computers_ban_id; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.computers_ban_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.computers_ban_id OWNER TO sru;

--
-- Name: computers_bans; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.computers_bans (
    id bigint DEFAULT nextval('public.computers_ban_id'::regclass) NOT NULL,
    computer_id bigint NOT NULL,
    penalty_id bigint NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.computers_bans OWNER TO sru;

--
-- Name: TABLE computers_bans; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.computers_bans IS 'zbanowane komputery';


--
-- Name: COLUMN computers_bans.computer_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_bans.computer_id IS 'ktory komputer';


--
-- Name: COLUMN computers_bans.penalty_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_bans.penalty_id IS 'ktora kara';


--
-- Name: computers_history_computer_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.computers_history_computer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.computers_history_computer_id_seq OWNER TO sru;

--
-- Name: computers_history_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.computers_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.computers_history_id_seq OWNER TO sru;

--
-- Name: computers_history; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.computers_history (
    computer_id bigint DEFAULT nextval('public.computers_history_computer_id_seq'::regclass) NOT NULL,
    host character varying(50) NOT NULL,
    mac macaddr NOT NULL,
    ipv4 inet NOT NULL,
    user_id bigint,
    location_id bigint,
    avail_to timestamp with time zone,
    modified_by bigint,
    modified_at timestamp with time zone DEFAULT now() NOT NULL,
    comment text NOT NULL,
    can_admin boolean DEFAULT false NOT NULL,
    id bigint DEFAULT nextval('public.computers_history_id_seq'::regclass) NOT NULL,
    active boolean NOT NULL,
    type_id smallint,
    exadmin boolean DEFAULT false NOT NULL,
    carer_id bigint,
    master_host_id bigint,
    auto_deactivation boolean DEFAULT true NOT NULL,
    device_model_id bigint
);


ALTER TABLE public.computers_history OWNER TO sru;

--
-- Name: TABLE computers_history; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.computers_history IS 'historia zmian danych komputerow';


--
-- Name: COLUMN computers_history.host; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_history.host IS 'nazwa hosta';


--
-- Name: COLUMN computers_history.mac; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_history.mac IS 'adres mac karty sieciowej';


--
-- Name: COLUMN computers_history.ipv4; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_history.ipv4 IS 'adres ip';


--
-- Name: COLUMN computers_history.user_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_history.user_id IS 'uzytkownik, do ktorego nalezy ten komputer';


--
-- Name: COLUMN computers_history.location_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_history.location_id IS 'pokoj';


--
-- Name: COLUMN computers_history.avail_to; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_history.avail_to IS 'do kiedy jest wazna rejestracja';


--
-- Name: COLUMN computers_history.modified_by; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_history.modified_by IS 'kto wprowadzil te dane';


--
-- Name: COLUMN computers_history.modified_at; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_history.modified_at IS 'czas powstania tej wersji';


--
-- Name: COLUMN computers_history.comment; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_history.comment IS 'komentarz';


--
-- Name: COLUMN computers_history.can_admin; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.computers_history.can_admin IS 'komputer nalezy do administratora';


--
-- Name: countries_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.countries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.countries_id_seq OWNER TO sru;

--
-- Name: countries; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.countries (
    id bigint DEFAULT nextval('public.countries_id_seq'::regclass) NOT NULL,
    nationality character varying(50) NOT NULL
);


ALTER TABLE public.countries OWNER TO sru;

--
-- Name: device_models; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.device_models (
    id bigint NOT NULL,
    name character varying(32)
);


ALTER TABLE public.device_models OWNER TO sru;

--
-- Name: TABLE device_models; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.device_models IS 'modele urzadzen';


--
-- Name: device_models_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.device_models_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.device_models_id_seq OWNER TO sru;

--
-- Name: device_models_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.device_models_id_seq OWNED BY public.device_models.id;


--
-- Name: devices; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.devices (
    id bigint NOT NULL,
    device_model_id bigint NOT NULL,
    used boolean NOT NULL,
    modified_by bigint,
    modified_at timestamp with time zone DEFAULT now() NOT NULL,
    location_id bigint NOT NULL,
    comment text,
    inventory_card_id bigint,
    inoperational boolean NOT NULL
);


ALTER TABLE public.devices OWNER TO sru;

--
-- Name: TABLE devices; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.devices IS 'pozostale urzadzenia i sprzety';


--
-- Name: devices_history; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.devices_history (
    id bigint NOT NULL,
    device_id bigint NOT NULL,
    device_model_id bigint NOT NULL,
    used boolean NOT NULL,
    modified_by bigint,
    modified_at timestamp with time zone DEFAULT now() NOT NULL,
    location_id bigint NOT NULL,
    comment text,
    inoperational boolean NOT NULL
);


ALTER TABLE public.devices_history OWNER TO sru;

--
-- Name: TABLE devices_history; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.devices_history IS 'historia pozostalych urzadzen i sprzetow';


--
-- Name: devices_history_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.devices_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.devices_history_id_seq OWNER TO sru;

--
-- Name: devices_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.devices_history_id_seq OWNED BY public.devices_history.id;


--
-- Name: devices_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.devices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.devices_id_seq OWNER TO sru;

--
-- Name: devices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.devices_id_seq OWNED BY public.devices.id;


--
-- Name: dormitories_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.dormitories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dormitories_id_seq OWNER TO sru;

--
-- Name: dormitories; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.dormitories (
    id bigint DEFAULT nextval('public.dormitories_id_seq'::regclass) NOT NULL,
    name character varying(255) NOT NULL,
    alias character varying(10) NOT NULL,
    users_count integer DEFAULT 0 NOT NULL,
    computers_count integer DEFAULT 0 NOT NULL,
    users_max integer DEFAULT 0 NOT NULL,
    computers_max integer DEFAULT 0 NOT NULL,
    name_en character varying(255),
    display_order integer,
    campus integer DEFAULT 1 NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.dormitories OWNER TO sru;

--
-- Name: TABLE dormitories; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.dormitories IS 'akademiki';


--
-- Name: COLUMN dormitories.name; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.dormitories.name IS 'pelna nazwa';


--
-- Name: COLUMN dormitories.alias; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.dormitories.alias IS 'skrot, uzywany do budowy url-i';


--
-- Name: COLUMN dormitories.users_count; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.dormitories.users_count IS 'ilosc zarejestrowanych uzytkownikow';


--
-- Name: COLUMN dormitories.computers_count; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.dormitories.computers_count IS 'ilosc zarejestrowanych komputerow';


--
-- Name: duty_hours_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.duty_hours_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.duty_hours_id_seq OWNER TO sru;

--
-- Name: duty_hours; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.duty_hours (
    id bigint DEFAULT nextval('public.duty_hours_id_seq'::regclass) NOT NULL,
    admin_id bigint NOT NULL,
    day integer NOT NULL,
    start_hour integer NOT NULL,
    end_hour integer NOT NULL,
    active boolean DEFAULT true NOT NULL,
    comment text
);


ALTER TABLE public.duty_hours OWNER TO sru;

--
-- Name: COLUMN duty_hours.admin_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.duty_hours.admin_id IS 'Administrator';


--
-- Name: COLUMN duty_hours.start_hour; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.duty_hours.start_hour IS 'Godzina rozpoczecia';


--
-- Name: COLUMN duty_hours.end_hour; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.duty_hours.end_hour IS 'Godzina zakonczenia';


--
-- Name: COLUMN duty_hours.active; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.duty_hours.active IS 'Czy aktywny (nieodwolany)';


--
-- Name: faulties_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.faulties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.faulties_id_seq OWNER TO sru;

--
-- Name: faculties; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.faculties (
    id bigint DEFAULT nextval('public.faulties_id_seq'::regclass) NOT NULL,
    name character varying(255) NOT NULL,
    alias character varying(10) NOT NULL,
    users_count integer DEFAULT 0 NOT NULL,
    computers_count integer DEFAULT 0 NOT NULL,
    name_en character varying(255)
);


ALTER TABLE public.faculties OWNER TO sru;

--
-- Name: TABLE faculties; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.faculties IS 'wydzialy';


--
-- Name: COLUMN faculties.name; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.faculties.name IS 'nazwa wydzialu';


--
-- Name: COLUMN faculties.alias; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.faculties.alias IS 'skrot nazwy, uzywany do budowy url-i';


--
-- Name: COLUMN faculties.users_count; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.faculties.users_count IS 'ilosc zarejestrowanych uzytkownikow';


--
-- Name: COLUMN faculties.computers_count; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.faculties.computers_count IS 'ilosc zarejestrowanych komputerow';


--
-- Name: fw_exception_applications; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.fw_exception_applications (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    self_education boolean NOT NULL,
    university_education boolean NOT NULL,
    comment text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    skos_opinion boolean,
    skos_comment text,
    skos_opinion_at timestamp with time zone,
    skos_opinion_by bigint,
    sspg_opinion boolean,
    sspg_comment text,
    sspg_opinion_at timestamp with time zone,
    valid_to timestamp with time zone,
    sspg_opinion_by bigint
);


ALTER TABLE public.fw_exception_applications OWNER TO sru;

--
-- Name: TABLE fw_exception_applications; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.fw_exception_applications IS 'wnioski o wyjatki w firewallu';


--
-- Name: COLUMN fw_exception_applications.skos_opinion; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.fw_exception_applications.skos_opinion IS 'opinia SKOS';


--
-- Name: COLUMN fw_exception_applications.sspg_opinion; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.fw_exception_applications.sspg_opinion IS 'opinia SSPG';


--
-- Name: COLUMN fw_exception_applications.valid_to; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.fw_exception_applications.valid_to IS 'waznosc wniosku (i stworzonych wyjatkow)';


--
-- Name: fw_exception_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.fw_exception_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fw_exception_applications_id_seq OWNER TO sru;

--
-- Name: fw_exception_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.fw_exception_applications_id_seq OWNED BY public.fw_exception_applications.id;


--
-- Name: fw_exceptions; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.fw_exceptions (
    id bigint NOT NULL,
    computer_id bigint NOT NULL,
    port integer NOT NULL,
    active boolean NOT NULL,
    fw_exception_application_id bigint,
    modified_by bigint,
    modified_at timestamp with time zone DEFAULT now() NOT NULL,
    waiting boolean DEFAULT false NOT NULL,
    CONSTRAINT fw_exceptions_check CHECK ((NOT ((active IS TRUE) AND (waiting IS TRUE))))
);


ALTER TABLE public.fw_exceptions OWNER TO sru;

--
-- Name: TABLE fw_exceptions; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.fw_exceptions IS 'wyjatki w firewallu';


--
-- Name: COLUMN fw_exceptions.waiting; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.fw_exceptions.waiting IS 'oczekuje na rozpatrzenie';


--
-- Name: fw_exceptions_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.fw_exceptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fw_exceptions_id_seq OWNER TO sru;

--
-- Name: fw_exceptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.fw_exceptions_id_seq OWNED BY public.fw_exceptions.id;


--
-- Name: inventory_cards; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.inventory_cards (
    id bigint NOT NULL,
    modified_by bigint,
    modified_at timestamp with time zone DEFAULT now() NOT NULL,
    dormitory_id bigint NOT NULL,
    serial_no character varying(32),
    inventory_no character varying(32),
    received date,
    comment text
);


ALTER TABLE public.inventory_cards OWNER TO sru;

--
-- Name: TABLE inventory_cards; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.inventory_cards IS 'karty wyposazenia';


--
-- Name: COLUMN inventory_cards.serial_no; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.inventory_cards.serial_no IS 'numer seryjny';


--
-- Name: COLUMN inventory_cards.inventory_no; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.inventory_cards.inventory_no IS 'numer inwentarzowy';


--
-- Name: COLUMN inventory_cards.received; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.inventory_cards.received IS 'data dodania na stan';


--
-- Name: inventory_cards_history; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.inventory_cards_history (
    id bigint NOT NULL,
    inventory_card_id bigint NOT NULL,
    modified_by bigint,
    modified_at timestamp with time zone DEFAULT now() NOT NULL,
    dormitory_id bigint NOT NULL,
    serial_no character varying(32),
    inventory_no character varying(32),
    received date,
    comment text
);


ALTER TABLE public.inventory_cards_history OWNER TO sru;

--
-- Name: TABLE inventory_cards_history; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.inventory_cards_history IS 'historia kart wyposazenia';


--
-- Name: inventory_cards_history_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.inventory_cards_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventory_cards_history_id_seq OWNER TO sru;

--
-- Name: inventory_cards_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.inventory_cards_history_id_seq OWNED BY public.inventory_cards_history.id;


--
-- Name: inventory_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.inventory_cards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventory_cards_id_seq OWNER TO sru;

--
-- Name: inventory_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.inventory_cards_id_seq OWNED BY public.inventory_cards.id;


--
-- Name: ipv4s; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.ipv4s (
    ip inet NOT NULL,
    dormitory_id bigint,
    vlan bigint DEFAULT 42 NOT NULL
);


ALTER TABLE public.ipv4s OWNER TO sru;

--
-- Name: TABLE ipv4s; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.ipv4s IS 'dostepne adresy ip';


--
-- Name: COLUMN ipv4s.ip; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.ipv4s.ip IS 'adres ip';


--
-- Name: COLUMN ipv4s.dormitory_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.ipv4s.dormitory_id IS 'akademik';


--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.locations_id_seq OWNER TO sru;

--
-- Name: locations; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.locations (
    id bigint DEFAULT nextval('public.locations_id_seq'::regclass) NOT NULL,
    alias character varying(10) NOT NULL,
    comment text DEFAULT ''::text NOT NULL,
    users_count integer DEFAULT 0 NOT NULL,
    computers_count integer DEFAULT 0 NOT NULL,
    dormitory_id bigint NOT NULL,
    users_max smallint,
    modified_by bigint,
    modified_at timestamp with time zone DEFAULT now(),
    type_id smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.locations OWNER TO sru;

--
-- Name: TABLE locations; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.locations IS 'pokoje';


--
-- Name: COLUMN locations.alias; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.locations.alias IS 'unikalna nazwa pokoju, uzywana do budowy url-i';


--
-- Name: COLUMN locations.comment; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.locations.comment IS 'komentarz do pokoju';


--
-- Name: COLUMN locations.users_count; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.locations.users_count IS 'ilosc zarejestrowanych uzytkownikow';


--
-- Name: COLUMN locations.computers_count; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.locations.computers_count IS 'ilosc zarejestrowanych komputerow';


--
-- Name: COLUMN locations.dormitory_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.locations.dormitory_id IS 'akademik, w ktorym znajduje sie pokoj';


--
-- Name: COLUMN locations.users_max; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.locations.users_max IS 'maksymalna ilosc osob w pokoju';


--
-- Name: locations_history; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.locations_history (
    id bigint NOT NULL,
    location_id bigint NOT NULL,
    comment text NOT NULL,
    modified_by bigint,
    modified_at timestamp with time zone DEFAULT now(),
    users_max smallint,
    type_id smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.locations_history OWNER TO sru;

--
-- Name: TABLE locations_history; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.locations_history IS 'historia lokacji';


--
-- Name: locations_history_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.locations_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.locations_history_id_seq OWNER TO sru;

--
-- Name: locations_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.locations_history_id_seq OWNED BY public.locations_history.id;


--
-- Name: penalties; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.penalties (
    id bigint DEFAULT nextval('public.bans_id_seq'::regclass) NOT NULL,
    created_by bigint NOT NULL,
    user_id bigint,
    type_id smallint DEFAULT 1 NOT NULL,
    start_at timestamp with time zone DEFAULT now() NOT NULL,
    end_at timestamp with time zone NOT NULL,
    comment text,
    modified_by bigint,
    reason text NOT NULL,
    modified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    amnesty_at timestamp with time zone,
    amnesty_after timestamp with time zone,
    amnesty_by bigint,
    active boolean DEFAULT true NOT NULL,
    template_id smallint
);


ALTER TABLE public.penalties OWNER TO sru;

--
-- Name: TABLE penalties; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.penalties IS 'kary nalozone na uzytkownikow';


--
-- Name: COLUMN penalties.created_by; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalties.created_by IS 'tworca kary';


--
-- Name: COLUMN penalties.user_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalties.user_id IS 'ukarany uzytkownik';


--
-- Name: COLUMN penalties.type_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalties.type_id IS 'typ kary: ostrzezenie, wszystko, komputer itp';


--
-- Name: COLUMN penalties.start_at; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalties.start_at IS 'od kiedy kara obowiazuje';


--
-- Name: COLUMN penalties.end_at; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalties.end_at IS 'do kiedy kara obowiazuje';


--
-- Name: COLUMN penalties.comment; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalties.comment IS 'komentarze administratorow';


--
-- Name: COLUMN penalties.modified_by; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalties.modified_by IS 'kto modyfikowal ostanio';


--
-- Name: COLUMN penalties.reason; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalties.reason IS 'powod(dla uzytkownika)';


--
-- Name: COLUMN penalties.modified_at; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalties.modified_at IS 'kiedy ostanio modyfikowano';


--
-- Name: COLUMN penalties.created_at; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalties.created_at IS 'kiedy utworzono kare';


--
-- Name: COLUMN penalties.amnesty_at; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalties.amnesty_at IS 'kiedy udzielono amnesti';


--
-- Name: COLUMN penalties.amnesty_after; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalties.amnesty_after IS 'od kiedy dopuszcza sie mozliwosc amnesti';


--
-- Name: COLUMN penalties.amnesty_by; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalties.amnesty_by IS 'kto udzielil amnesti';


--
-- Name: COLUMN penalties.template_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalties.template_id IS 'id szablonu, na podstawie ktorego zostala utworzona kara';


--
-- Name: penalties_history; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.penalties_history (
    id bigint NOT NULL,
    penalty_id bigint NOT NULL,
    end_at timestamp with time zone NOT NULL,
    comment text,
    modified_by bigint,
    reason text NOT NULL,
    modified_at timestamp with time zone,
    amnesty_after timestamp with time zone
);


ALTER TABLE public.penalties_history OWNER TO sru;

--
-- Name: TABLE penalties_history; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.penalties_history IS 'historia kar nalozonych na uzytkownikow';


--
-- Name: penalties_history_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.penalties_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.penalties_history_id_seq OWNER TO sru;

--
-- Name: penalties_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.penalties_history_id_seq OWNED BY public.penalties_history.id;


--
-- Name: penalty_templates_id; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.penalty_templates_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.penalty_templates_id OWNER TO sru;

--
-- Name: penalty_templates; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.penalty_templates (
    id bigint DEFAULT nextval('public.penalty_templates_id'::regclass) NOT NULL,
    title character varying(100) NOT NULL,
    description text,
    penalty_type_id smallint NOT NULL,
    duration integer NOT NULL,
    amnesty_after integer DEFAULT 0 NOT NULL,
    reason text DEFAULT ''::text NOT NULL,
    reason_en text DEFAULT ''::text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.penalty_templates OWNER TO sru;

--
-- Name: TABLE penalty_templates; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.penalty_templates IS 'szablony kar';


--
-- Name: COLUMN penalty_templates.title; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalty_templates.title IS 'tytul';


--
-- Name: COLUMN penalty_templates.description; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalty_templates.description IS 'opis dla administratora';


--
-- Name: COLUMN penalty_templates.penalty_type_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalty_templates.penalty_type_id IS 'typ kary: ostrzezenie, wszystko, komputer it';


--
-- Name: COLUMN penalty_templates.duration; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalty_templates.duration IS 'czas trwania kary';


--
-- Name: COLUMN penalty_templates.amnesty_after; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.penalty_templates.amnesty_after IS 'czas po ktorym mozna udzielic amnesti';


--
-- Name: radacct_srv; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.radacct_srv (
    radacctid bigint NOT NULL,
    acctsessionid text NOT NULL,
    acctuniqueid text NOT NULL,
    username text,
    realm text,
    nasipaddress inet NOT NULL,
    nasportid text,
    nasporttype text,
    acctstarttime timestamp with time zone,
    acctupdatetime timestamp with time zone,
    acctstoptime timestamp with time zone,
    acctinterval bigint,
    acctsessiontime bigint,
    acctauthentic text,
    connectinfo_start text,
    connectinfo_stop text,
    acctinputoctets bigint,
    acctoutputoctets bigint,
    calledstationid text,
    callingstationid text,
    acctterminatecause text,
    servicetype text,
    framedprotocol text,
    framedipaddress inet,
    framedipv6address inet,
    framedipv6prefix inet,
    framedinterfaceid text,
    delegatedipv6prefix inet,
    class text
);


ALTER TABLE public.radacct_srv OWNER TO sru;

--
-- Name: radacct_srv_radacctid_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.radacct_srv_radacctid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.radacct_srv_radacctid_seq OWNER TO sru;

--
-- Name: radacct_srv_radacctid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.radacct_srv_radacctid_seq OWNED BY public.radacct_srv.radacctid;


--
-- Name: radacct_sw; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.radacct_sw (
    radacctid bigint NOT NULL,
    acctsessionid text NOT NULL,
    acctuniqueid text NOT NULL,
    username text,
    realm text,
    nasipaddress inet NOT NULL,
    nasportid text,
    nasporttype text,
    acctstarttime timestamp with time zone,
    acctupdatetime timestamp with time zone,
    acctstoptime timestamp with time zone,
    acctinterval bigint,
    acctsessiontime bigint,
    acctauthentic text,
    connectinfo_start text,
    connectinfo_stop text,
    acctinputoctets bigint,
    acctoutputoctets bigint,
    calledstationid text,
    callingstationid text,
    acctterminatecause text,
    servicetype text,
    framedprotocol text,
    framedipaddress inet,
    framedipv6address inet,
    framedipv6prefix inet,
    framedinterfaceid text,
    delegatedipv6prefix inet,
    class text
);


ALTER TABLE public.radacct_sw OWNER TO sru;

--
-- Name: radacct_sw_radacctid_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.radacct_sw_radacctid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.radacct_sw_radacctid_seq OWNER TO sru;

--
-- Name: radacct_sw_radacctid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.radacct_sw_radacctid_seq OWNED BY public.radacct_sw.radacctid;


--
-- Name: radacct_wifi; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.radacct_wifi (
    radacctid bigint NOT NULL,
    acctsessionid text NOT NULL,
    acctuniqueid text NOT NULL,
    username text,
    realm text,
    nasipaddress inet NOT NULL,
    nasportid text,
    nasporttype text,
    acctstarttime timestamp with time zone,
    acctupdatetime timestamp with time zone,
    acctstoptime timestamp with time zone,
    acctinterval bigint,
    acctsessiontime bigint,
    acctauthentic text,
    connectinfo_start text,
    connectinfo_stop text,
    acctinputoctets bigint,
    acctoutputoctets bigint,
    calledstationid text,
    callingstationid text,
    acctterminatecause text,
    servicetype text,
    framedprotocol text,
    framedipaddress inet,
    framedipv6address inet,
    framedipv6prefix inet,
    framedinterfaceid text,
    delegatedipv6prefix inet,
    class text
);


ALTER TABLE public.radacct_wifi OWNER TO sru;

--
-- Name: radacct_wifi_radacctid_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.radacct_wifi_radacctid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.radacct_wifi_radacctid_seq OWNER TO sru;

--
-- Name: radacct_wifi_radacctid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.radacct_wifi_radacctid_seq OWNED BY public.radacct_wifi.radacctid;


--
-- Name: radius_user_device; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.radius_user_device (
    id integer NOT NULL,
    radius_user_id integer NOT NULL,
    mac character varying NOT NULL,
    lastlogin timestamp without time zone DEFAULT now() NOT NULL,
    firstlogin timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.radius_user_device OWNER TO sru;

--
-- Name: radius_user_device_20220928; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.radius_user_device_20220928 (
    id integer,
    radius_user_id integer,
    mac character varying,
    lastlogin timestamp without time zone,
    firstlogin timestamp without time zone
);


ALTER TABLE public.radius_user_device_20220928 OWNER TO sru;

--
-- Name: radius_user_device_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.radius_user_device_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.radius_user_device_id_seq OWNER TO sru;

--
-- Name: radius_user_device_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.radius_user_device_id_seq OWNED BY public.radius_user_device.id;


--
-- Name: radius_users; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.radius_users (
    id integer DEFAULT public.next_free_id_from('radius_users'::text) NOT NULL,
    username character varying NOT NULL,
    lastlogin timestamp without time zone DEFAULT now() NOT NULL,
    firstlogin timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.radius_users OWNER TO sru;

--
-- Name: radius_users_20220928; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.radius_users_20220928 (
    id integer,
    username character varying,
    lastlogin timestamp without time zone,
    firstlogin timestamp without time zone
);


ALTER TABLE public.radius_users_20220928 OWNER TO sru;

--
-- Name: radius_users_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.radius_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.radius_users_id_seq OWNER TO sru;

--
-- Name: radius_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.radius_users_id_seq OWNED BY public.radius_users.id;


--
-- Name: radpostauth_srv; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.radpostauth_srv (
    id bigint NOT NULL,
    username text NOT NULL,
    reply text,
    calledstationid text,
    callingstationid text,
    authdate timestamp with time zone DEFAULT now() NOT NULL,
    class text,
    nasportid text,
    nasipaddress text
);


ALTER TABLE public.radpostauth_srv OWNER TO sru;

--
-- Name: radpostauth_srv_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.radpostauth_srv_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.radpostauth_srv_id_seq OWNER TO sru;

--
-- Name: radpostauth_srv_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.radpostauth_srv_id_seq OWNED BY public.radpostauth_srv.id;


--
-- Name: radpostauth_sw; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.radpostauth_sw (
    id bigint NOT NULL,
    username text NOT NULL,
    reply text,
    nasipaddress text,
    nasportid text,
    authdate timestamp with time zone DEFAULT now() NOT NULL,
    calledstationid text,
    callingstationid text,
    class text
);


ALTER TABLE public.radpostauth_sw OWNER TO sru;

--
-- Name: radpostauth_sw_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.radpostauth_sw_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.radpostauth_sw_id_seq OWNER TO sru;

--
-- Name: radpostauth_sw_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.radpostauth_sw_id_seq OWNED BY public.radpostauth_sw.id;


--
-- Name: radpostauth_wifi; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.radpostauth_wifi (
    id bigint NOT NULL,
    username text NOT NULL,
    reply text,
    calledstationid text,
    callingstationid text,
    authdate timestamp with time zone DEFAULT now() NOT NULL,
    class text,
    nasportid text,
    nasipaddress text
);


ALTER TABLE public.radpostauth_wifi OWNER TO sru;

--
-- Name: radpostauth_wifi_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.radpostauth_wifi_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.radpostauth_wifi_id_seq OWNER TO sru;

--
-- Name: radpostauth_wifi_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.radpostauth_wifi_id_seq OWNED BY public.radpostauth_wifi.id;


--
-- Name: switches_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.switches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.switches_id_seq OWNER TO sru;

--
-- Name: switches; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.switches (
    id bigint DEFAULT nextval('public.switches_id_seq'::regclass) NOT NULL,
    model bigint NOT NULL,
    comment text,
    inoperational boolean NOT NULL,
    hierarchy_no integer,
    ipv4 inet,
    lab boolean DEFAULT false,
    location_id bigint NOT NULL,
    inventory_card_id bigint NOT NULL,
    modified_by bigint,
    modified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.switches OWNER TO sru;

--
-- Name: COLUMN switches.inoperational; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.switches.inoperational IS 'czy sprawny';


--
-- Name: COLUMN switches.hierarchy_no; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.switches.hierarchy_no IS 'nr w hierarchi DSu';


--
-- Name: COLUMN switches.lab; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.switches.lab IS 'czy switch labowy';


--
-- Name: switches_firmware; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.switches_firmware (
    id integer NOT NULL,
    firmware character varying NOT NULL
);


ALTER TABLE public.switches_firmware OWNER TO sru;

--
-- Name: switches_firmware_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.switches_firmware_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.switches_firmware_id_seq OWNER TO sru;

--
-- Name: switches_firmware_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.switches_firmware_id_seq OWNED BY public.switches_firmware.id;


--
-- Name: switches_history; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.switches_history (
    id bigint NOT NULL,
    switch_id bigint NOT NULL,
    modified_by bigint,
    modified_at timestamp with time zone DEFAULT now() NOT NULL,
    location_id bigint NOT NULL,
    model bigint NOT NULL,
    inoperational boolean NOT NULL,
    hierarchy_no integer,
    ipv4 inet,
    comment text
);


ALTER TABLE public.switches_history OWNER TO sru;

--
-- Name: TABLE switches_history; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.switches_history IS 'historia switchy';


--
-- Name: switches_history_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.switches_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.switches_history_id_seq OWNER TO sru;

--
-- Name: switches_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.switches_history_id_seq OWNED BY public.switches_history.id;


--
-- Name: switches_type_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.switches_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.switches_type_id_seq OWNER TO sru;

--
-- Name: switches_model; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.switches_model (
    id bigint DEFAULT nextval('public.switches_type_id_seq'::regclass) NOT NULL,
    model_name character varying(32) NOT NULL,
    model_no character varying(8) NOT NULL,
    ports_no integer NOT NULL,
    sfp_ports_no integer DEFAULT 4 NOT NULL,
    firmware_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.switches_model OWNER TO sru;

--
-- Name: COLUMN switches_model.model_name; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.switches_model.model_name IS 'opisowa nazwa modelu';


--
-- Name: COLUMN switches_model.model_no; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.switches_model.model_no IS 'kod modelu wg producenta';


--
-- Name: COLUMN switches_model.ports_no; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.switches_model.ports_no IS 'liczba portow';


--
-- Name: switches_port_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.switches_port_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.switches_port_id_seq OWNER TO sru;

--
-- Name: switches_port; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.switches_port (
    id bigint DEFAULT nextval('public.switches_port_id_seq'::regclass) NOT NULL,
    switch bigint NOT NULL,
    location bigint,
    ordinal_no integer NOT NULL,
    comment character varying(255),
    connected_switch bigint,
    is_admin boolean DEFAULT false NOT NULL,
    penalty_id bigint
);


ALTER TABLE public.switches_port OWNER TO sru;

--
-- Name: COLUMN switches_port.location; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.switches_port.location IS 'lokalizacja podlaczona do portu';


--
-- Name: COLUMN switches_port.ordinal_no; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.switches_port.ordinal_no IS 'nr portu na switchu';


--
-- Name: COLUMN switches_port.connected_switch; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.switches_port.connected_switch IS 'podlaczony do portu switch';


--
-- Name: COLUMN switches_port.is_admin; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.switches_port.is_admin IS 'czy port admina';


--
-- Name: text_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.text_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.text_id_seq OWNER TO sru;

--
-- Name: text; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.text (
    id bigint DEFAULT nextval('public.text_id_seq'::regclass) NOT NULL,
    alias text NOT NULL,
    title text NOT NULL,
    content text NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_by bigint
);


ALTER TABLE public.text OWNER TO sru;

--
-- Name: TABLE text; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.text IS 'statyczne strony tekstowe';


--
-- Name: COLUMN text.alias; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.text.alias IS '"url"';


--
-- Name: COLUMN text.title; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.text.title IS 'tytul';


--
-- Name: COLUMN text.content; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.text.content IS 'tresc glowna';


--
-- Name: COLUMN text.modified_at; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.text.modified_at IS 'data ostatniej modyfikacji';


--
-- Name: COLUMN text.modified_by; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.text.modified_by IS 'kto dokonal modyfikacji';


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO sru;

--
-- Name: users; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.users (
    id bigint DEFAULT nextval('public.users_id_seq'::regclass) NOT NULL,
    login character varying NOT NULL,
    password character(32) NOT NULL,
    surname character varying(100) NOT NULL,
    email character varying(100),
    faculty_id bigint,
    study_year_id smallint,
    location_id bigint NOT NULL,
    bans smallint DEFAULT 0 NOT NULL,
    modified_by bigint,
    modified_at timestamp with time zone DEFAULT now() NOT NULL,
    comment text DEFAULT ''::text NOT NULL,
    name character varying(100) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    banned boolean DEFAULT false NOT NULL,
    last_login_at timestamp with time zone,
    last_login_ip inet,
    lang character(2) DEFAULT 'pl'::bpchar,
    referral_start timestamp with time zone,
    referral_end timestamp with time zone,
    registry_no integer,
    update_needed boolean DEFAULT true NOT NULL,
    change_password_needed boolean DEFAULT false NOT NULL,
    type_id smallint DEFAULT 1 NOT NULL,
    last_inv_login_at timestamp with time zone,
    last_inv_login_ip inet,
    nationality bigint,
    address text,
    birth_date timestamp with time zone,
    birth_place character varying(100),
    pesel character(11),
    document_type smallint DEFAULT 0 NOT NULL,
    document_number character varying(20),
    user_phone_number character varying(20),
    guardian_phone_number character varying(20),
    sex boolean DEFAULT false NOT NULL,
    last_location_change timestamp with time zone,
    comment_skos text DEFAULT ''::text NOT NULL,
    over_limit boolean DEFAULT false NOT NULL,
    to_deactivate boolean DEFAULT false NOT NULL,
    wifi_password character varying DEFAULT upper(substr(md5((random())::text), 0, 11)) NOT NULL
);


ALTER TABLE public.users OWNER TO sru;

--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.users IS 'uzytkownicy sieci';


--
-- Name: COLUMN users.login; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.login IS 'login';


--
-- Name: COLUMN users.password; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.password IS 'haslo zakodowane md5';


--
-- Name: COLUMN users.surname; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.surname IS 'nazwisko';


--
-- Name: COLUMN users.email; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.email IS 'email';


--
-- Name: COLUMN users.faculty_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.faculty_id IS 'wydzial ,jezeli dotyczy';


--
-- Name: COLUMN users.study_year_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.study_year_id IS 'identyfikator roku studiow, jezeli dotyczy';


--
-- Name: COLUMN users.location_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.location_id IS 'miejsce zamieszkania';


--
-- Name: COLUMN users.bans; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.bans IS 'ilosc otrzymanych banow';


--
-- Name: COLUMN users.modified_by; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.modified_by IS 'kto wprowadzil te dane';


--
-- Name: COLUMN users.modified_at; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.modified_at IS 'czas powstania tej wersji';


--
-- Name: COLUMN users.comment; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.comment IS 'komentarze dotyczace uzytkownika';


--
-- Name: COLUMN users.name; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.name IS 'imie';


--
-- Name: COLUMN users.active; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.active IS 'czy uzytkownik moze logowac sie do systemu?';


--
-- Name: COLUMN users.banned; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.banned IS 'czy uzytkownik jest w tej chwili zabanowany?';


--
-- Name: COLUMN users.referral_start; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.referral_start IS 'data poczatku skierowania';


--
-- Name: COLUMN users.referral_end; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.referral_end IS 'data konca skierowania';


--
-- Name: COLUMN users.registry_no; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.registry_no IS 'nr indeksu';


--
-- Name: COLUMN users.update_needed; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.update_needed IS 'dane wymagaja uaktualnienia?';


--
-- Name: COLUMN users.change_password_needed; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.change_password_needed IS 'haslo wymaga zmiany?';


--
-- Name: COLUMN users.last_location_change; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users.last_location_change IS 'data ostatniej zmiany lokalizacji';


--
-- Name: users_functions; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.users_functions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    function_id smallint NOT NULL,
    dormitory_id bigint,
    comment character varying(64)
);


ALTER TABLE public.users_functions OWNER TO sru;

--
-- Name: TABLE users_functions; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.users_functions IS 'funkcje uzytkownikow na rzecz DS i Osiedla';


--
-- Name: users_functions_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.users_functions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_functions_id_seq OWNER TO sru;

--
-- Name: users_functions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.users_functions_id_seq OWNED BY public.users_functions.id;


--
-- Name: users_history_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.users_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_history_id_seq OWNER TO sru;

--
-- Name: users_history; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.users_history (
    user_id bigint NOT NULL,
    name character varying(50) NOT NULL,
    surname character varying(100) NOT NULL,
    email character varying(100),
    faculty_id bigint,
    study_year_id smallint,
    location_id bigint NOT NULL,
    modified_by bigint,
    modified_at timestamp with time zone NOT NULL,
    comment text NOT NULL,
    id bigint DEFAULT nextval('public.users_history_id_seq'::regclass) NOT NULL,
    login character varying NOT NULL,
    active boolean NOT NULL,
    referral_start timestamp with time zone,
    referral_end timestamp with time zone,
    registry_no integer,
    update_needed boolean DEFAULT false NOT NULL,
    change_password_needed boolean DEFAULT false NOT NULL,
    password_changed timestamp with time zone,
    lang character(2) DEFAULT 'pl'::bpchar,
    type_id smallint,
    nationality bigint,
    address text,
    birth_date timestamp with time zone,
    birth_place text,
    pesel text,
    document_type text,
    document_number text,
    user_phone_number text,
    guardian_phone_number text,
    sex boolean,
    last_location_change timestamp with time zone,
    comment_skos text DEFAULT ''::text NOT NULL,
    over_limit boolean DEFAULT false NOT NULL,
    to_deactivate boolean DEFAULT false NOT NULL
);


ALTER TABLE public.users_history OWNER TO sru;

--
-- Name: TABLE users_history; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TABLE public.users_history IS 'historia zmian danych uzytkownikow';


--
-- Name: COLUMN users_history.user_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.user_id IS 'id uzytkownika';


--
-- Name: COLUMN users_history.name; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.name IS 'imie';


--
-- Name: COLUMN users_history.surname; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.surname IS 'nazwisko';


--
-- Name: COLUMN users_history.email; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.email IS 'email';


--
-- Name: COLUMN users_history.faculty_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.faculty_id IS 'wydzial';


--
-- Name: COLUMN users_history.study_year_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.study_year_id IS 'identyfikator roku studiow';


--
-- Name: COLUMN users_history.location_id; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.location_id IS 'miejsce zamieszkania';


--
-- Name: COLUMN users_history.modified_by; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.modified_by IS 'kto wprowadzil te dane';


--
-- Name: COLUMN users_history.modified_at; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.modified_at IS 'czas powstania tej wersji';


--
-- Name: COLUMN users_history.comment; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.comment IS 'komentarz';


--
-- Name: COLUMN users_history.login; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.login IS 'login';


--
-- Name: COLUMN users_history.referral_start; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.referral_start IS 'data poczatku skierowania';


--
-- Name: COLUMN users_history.referral_end; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.referral_end IS 'data konca skierowania';


--
-- Name: COLUMN users_history.registry_no; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.registry_no IS 'nr indeksu';


--
-- Name: COLUMN users_history.last_location_change; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_history.last_location_change IS 'data ostatniej zmiany lokalizacji';


--
-- Name: users_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.users_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_tokens_id_seq OWNER TO sru;

--
-- Name: users_tokens; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.users_tokens (
    id integer DEFAULT nextval('public.users_tokens_id_seq'::regclass) NOT NULL,
    user_id integer NOT NULL,
    token text NOT NULL,
    valid_to timestamp with time zone DEFAULT (now() + '7 days'::interval) NOT NULL,
    type smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.users_tokens OWNER TO sru;

--
-- Name: COLUMN users_tokens.valid_to; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_tokens.valid_to IS 'do kiedy token jest wazny';


--
-- Name: COLUMN users_tokens.type; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.users_tokens.type IS 'do czego moze byc ten token wykorzystany
0 - aktywacja konta';


--
-- Name: v_admins_cas; Type: VIEW; Schema: public; Owner: sru
--

CREATE VIEW public.v_admins_cas AS
 SELECT admins.login,
    admins.password_inner
   FROM public.admins
  WHERE (admins.active = true);


ALTER TABLE public.v_admins_cas OWNER TO sru;

--
-- Name: v_computers; Type: VIEW; Schema: public; Owner: sru
--

CREATE VIEW public.v_computers AS
 SELECT computers.mac,
    computers.ipv4,
    users.login
   FROM (public.computers
     JOIN public.users ON ((computers.user_id = users.id)))
  WHERE (computers.active = true);


ALTER TABLE public.v_computers OWNER TO sru;

--
-- Name: v_inventory_list; Type: VIEW; Schema: public; Owner: sru
--

CREATE VIEW public.v_inventory_list AS
 SELECT ic.id AS card_id,
    c.id,
    ic.dormitory_id AS ic_dormitory_id,
    l.dormitory_id,
    c.location_id,
    ic.serial_no,
    ic.inventory_no,
    ic.received,
    c.device_model_id,
    m.name AS device_model_name,
    1 AS table_id
   FROM (((public.computers c
     LEFT JOIN public.inventory_cards ic ON ((c.inventory_card_id = ic.id)))
     JOIN public.locations l ON ((c.location_id = l.id)))
     JOIN public.device_models m ON ((c.device_model_id = m.id)))
  WHERE ((c.type_id = 41) OR (c.type_id = 43))
UNION
 SELECT ic.id AS card_id,
    s.id,
    ic.dormitory_id AS ic_dormitory_id,
    l.dormitory_id,
    s.location_id,
    ic.serial_no,
    ic.inventory_no,
    ic.received,
    0 AS device_model_id,
    sm.model_name AS device_model_name,
    2 AS table_id
   FROM (((public.switches s
     LEFT JOIN public.inventory_cards ic ON ((s.inventory_card_id = ic.id)))
     JOIN public.locations l ON ((s.location_id = l.id)))
     JOIN public.switches_model sm ON ((s.model = sm.id)))
UNION
 SELECT ic.id AS card_id,
    d.id,
    ic.dormitory_id AS ic_dormitory_id,
    l.dormitory_id,
    d.location_id,
    ic.serial_no,
    ic.inventory_no,
    ic.received,
    d.device_model_id,
    m.name AS device_model_name,
    3 AS table_id
   FROM (((public.devices d
     LEFT JOIN public.inventory_cards ic ON ((d.inventory_card_id = ic.id)))
     JOIN public.locations l ON ((d.location_id = l.id)))
     JOIN public.device_models m ON ((d.device_model_id = m.id)));


ALTER TABLE public.v_inventory_list OWNER TO sru;

--
-- Name: v_radcheck_srv; Type: VIEW; Schema: public; Owner: sru
--

CREATE VIEW public.v_radcheck_srv AS
 SELECT (admins.id + 1000) AS id,
    admins.login AS username,
    'MD5-Password'::text AS attribute,
    admins.password_inner AS value,
    ':= '::text AS op
   FROM public.admins
  WHERE ((admins.type_id <= 4) AND (admins.active = true))
UNION
 SELECT 1 AS id,
    'healthcheck'::character varying AS username,
    'MD5-Password'::text AS attribute,
    'ffe6530f9329552b8eb9b707963b0080'::character(32) AS value,
    ':= '::text AS op;


ALTER TABLE public.v_radcheck_srv OWNER TO sru;

--
-- Name: v_radcheck_sw; Type: VIEW; Schema: public; Owner: sru
--

CREATE VIEW public.v_radcheck_sw AS
 SELECT (admins.id + 1000) AS id,
    admins.login AS username,
    'MD5-Password'::text AS attribute,
    admins.password_inner AS value,
    ':= '::text AS op
   FROM public.admins
  WHERE ((admins.type_id <= 4) AND (admins.active = true))
UNION
 SELECT 1 AS id,
    'healthcheck'::character varying AS username,
    'MD5-Password'::text AS attribute,
    'ffe6530f9329552b8eb9b707963b0080'::character(32) AS value,
    ':= '::text AS op;


ALTER TABLE public.v_radcheck_sw OWNER TO sru;

--
-- Name: v_radcheck_user; Type: VIEW; Schema: public; Owner: sru
--

CREATE VIEW public.v_radcheck_user AS
 SELECT (users.id + 1000) AS id,
    users.login AS username,
    'Cleartext-Password'::text AS attribute,
    users.wifi_password AS value,
    ':= '::text AS op
   FROM public.users
  WHERE (users.active = true)
UNION
 SELECT (admins.id + 100000) AS id,
    admins.login AS username,
    'Cleartext-Password'::text AS attribute,
    admins.wifi_password AS value,
    ':= '::text AS op
   FROM public.admins
  WHERE (admins.active = true)
UNION
 SELECT 1 AS id,
    'healthcheck'::character varying AS username,
    'Cleartext-Password'::text AS attribute,
    'H6tQjXQyb7'::character varying AS value,
    ':= '::text AS op
   FROM public.admins
  WHERE (admins.active = true);


ALTER TABLE public.v_radcheck_user OWNER TO sru;

--
-- Name: v_radreply; Type: VIEW; Schema: public; Owner: sru
--

CREATE VIEW public.v_radreply AS
 SELECT (admins.id + 1000) AS id,
    admins.login AS username,
    'APC-Service-Type'::text AS attribute,
    'Admin'::bpchar AS value,
    ':= '::text AS op
   FROM public.admins
  WHERE ((admins.type_id <= 4) AND (admins.active = true));


ALTER TABLE public.v_radreply OWNER TO sru;

--
-- Name: v_radusers; Type: VIEW; Schema: public; Owner: sru
--

CREATE VIEW public.v_radusers AS
 SELECT row_number() OVER (ORDER BY c.mac) AS id,
    c.mac AS username,
    'User-Name'::text AS attribute,
    c.mac AS value,
    ':='::text AS op
   FROM public.computers c,
    public.ipv4s i
  WHERE ((c.active = true) AND (c.ipv4 = i.ip) AND (i.vlan = 42));


ALTER TABLE public.v_radusers OWNER TO sru;

--
-- Name: v_radusers2vlans; Type: VIEW; Schema: public; Owner: sru
--

CREATE VIEW public.v_radusers2vlans AS
 SELECT row_number() OVER (ORDER BY foo.username) AS id,
    foo.username,
    foo.attribute,
    foo.value,
    foo.op
   FROM ( SELECT c.mac AS username,
            'Tunnel-Private-Group-Id'::text AS attribute,
            (i.vlan)::text AS value,
            ':='::text AS op
           FROM public.computers c,
            public.ipv4s i
          WHERE ((c.active = true) AND (c.banned = false) AND (c.ipv4 = i.ip) AND (i.vlan = 42))
        UNION
         SELECT c.mac AS username,
            'Tunnel-Private-Group-Id'::text AS attribute,
            '1045'::text AS value,
            ':='::text AS op
           FROM public.computers c
          WHERE ((c.active = true) AND (c.banned = true))
        UNION
         SELECT c.mac AS username,
            'Tunnel-Medium-Type'::text AS attribute,
            'IEEE-802'::text AS value,
            ':='::text AS op
           FROM public.computers c,
            public.ipv4s i
          WHERE ((c.active = true) AND (c.ipv4 = i.ip) AND (i.vlan = 42))
        UNION
         SELECT c.mac AS username,
            'Tunnel-Type'::text AS attribute,
            'VLAN'::text AS value,
            ':='::text AS op
           FROM public.computers c,
            public.ipv4s i
          WHERE ((c.active = true) AND (c.ipv4 = i.ip) AND (i.vlan = 42))) foo;


ALTER TABLE public.v_radusers2vlans OWNER TO sru;

--
-- Name: vlans; Type: TABLE; Schema: public; Owner: sru
--

CREATE TABLE public.vlans (
    id bigint NOT NULL,
    name character varying(20) NOT NULL,
    description character varying(100),
    task_export boolean DEFAULT false NOT NULL,
    domain_suffix character varying(20) DEFAULT 'ds.pg.gda.pl'::character varying NOT NULL
);


ALTER TABLE public.vlans OWNER TO sru;

--
-- Name: COLUMN vlans.task_export; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON COLUMN public.vlans.task_export IS 'czy wysylac dane do TASK';


--
-- Name: vlans_id_seq; Type: SEQUENCE; Schema: public; Owner: sru
--

CREATE SEQUENCE public.vlans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.vlans_id_seq OWNER TO sru;

--
-- Name: vlans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sru
--

ALTER SEQUENCE public.vlans_id_seq OWNED BY public.vlans.id;


--
-- Name: admins_history id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.admins_history ALTER COLUMN id SET DEFAULT nextval('public.admins_history_id_seq'::regclass);


--
-- Name: campuses id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.campuses ALTER COLUMN id SET DEFAULT nextval('public.campuses_id_seq'::regclass);


--
-- Name: device_models id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.device_models ALTER COLUMN id SET DEFAULT nextval('public.device_models_id_seq'::regclass);


--
-- Name: devices id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.devices ALTER COLUMN id SET DEFAULT nextval('public.devices_id_seq'::regclass);


--
-- Name: devices_history id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.devices_history ALTER COLUMN id SET DEFAULT nextval('public.devices_history_id_seq'::regclass);


--
-- Name: fw_exception_applications id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.fw_exception_applications ALTER COLUMN id SET DEFAULT nextval('public.fw_exception_applications_id_seq'::regclass);


--
-- Name: fw_exceptions id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.fw_exceptions ALTER COLUMN id SET DEFAULT nextval('public.fw_exceptions_id_seq'::regclass);


--
-- Name: inventory_cards id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.inventory_cards ALTER COLUMN id SET DEFAULT nextval('public.inventory_cards_id_seq'::regclass);


--
-- Name: inventory_cards_history id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.inventory_cards_history ALTER COLUMN id SET DEFAULT nextval('public.inventory_cards_history_id_seq'::regclass);


--
-- Name: locations_history id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.locations_history ALTER COLUMN id SET DEFAULT nextval('public.locations_history_id_seq'::regclass);


--
-- Name: penalties_history id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.penalties_history ALTER COLUMN id SET DEFAULT nextval('public.penalties_history_id_seq'::regclass);


--
-- Name: radacct_srv radacctid; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radacct_srv ALTER COLUMN radacctid SET DEFAULT nextval('public.radacct_srv_radacctid_seq'::regclass);


--
-- Name: radacct_sw radacctid; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radacct_sw ALTER COLUMN radacctid SET DEFAULT nextval('public.radacct_sw_radacctid_seq'::regclass);


--
-- Name: radacct_wifi radacctid; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radacct_wifi ALTER COLUMN radacctid SET DEFAULT nextval('public.radacct_wifi_radacctid_seq'::regclass);


--
-- Name: radius_user_device id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radius_user_device ALTER COLUMN id SET DEFAULT nextval('public.radius_user_device_id_seq'::regclass);


--
-- Name: radpostauth_srv id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radpostauth_srv ALTER COLUMN id SET DEFAULT nextval('public.radpostauth_srv_id_seq'::regclass);


--
-- Name: radpostauth_sw id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radpostauth_sw ALTER COLUMN id SET DEFAULT nextval('public.radpostauth_sw_id_seq'::regclass);


--
-- Name: radpostauth_wifi id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radpostauth_wifi ALTER COLUMN id SET DEFAULT nextval('public.radpostauth_wifi_id_seq'::regclass);


--
-- Name: switches_firmware id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_firmware ALTER COLUMN id SET DEFAULT nextval('public.switches_firmware_id_seq'::regclass);


--
-- Name: switches_history id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_history ALTER COLUMN id SET DEFAULT nextval('public.switches_history_id_seq'::regclass);


--
-- Name: users_functions id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users_functions ALTER COLUMN id SET DEFAULT nextval('public.users_functions_id_seq'::regclass);


--
-- Name: vlans id; Type: DEFAULT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.vlans ALTER COLUMN id SET DEFAULT nextval('public.vlans_id_seq'::regclass);


--
-- Name: admins_dormitories admins_dormitories_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.admins_dormitories
    ADD CONSTRAINT admins_dormitories_key UNIQUE (admin, dormitory);


--
-- Name: admins_dormitories admins_dormitories_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.admins_dormitories
    ADD CONSTRAINT admins_dormitories_pkey PRIMARY KEY (id);


--
-- Name: admins_history admins_history_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.admins_history
    ADD CONSTRAINT admins_history_pkey PRIMARY KEY (id);


--
-- Name: admins admins_login_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_login_key UNIQUE (login, active);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: campuses campuses_name_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.campuses
    ADD CONSTRAINT campuses_name_key UNIQUE (name);


--
-- Name: computers_aliases computers_aliases_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers_aliases
    ADD CONSTRAINT computers_aliases_pkey PRIMARY KEY (id);


--
-- Name: computers_bans computers_bans_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers_bans
    ADD CONSTRAINT computers_bans_pkey PRIMARY KEY (id);


--
-- Name: computers_history computers_history_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers_history
    ADD CONSTRAINT computers_history_pkey PRIMARY KEY (id);


--
-- Name: computers computers_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers
    ADD CONSTRAINT computers_pkey PRIMARY KEY (id);


--
-- Name: countries countries_nationality_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_nationality_key UNIQUE (nationality);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: device_models device_models_name_unique; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.device_models
    ADD CONSTRAINT device_models_name_unique UNIQUE (name);


--
-- Name: device_models device_models_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.device_models
    ADD CONSTRAINT device_models_pkey PRIMARY KEY (id);


--
-- Name: devices_history devices_history_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.devices_history
    ADD CONSTRAINT devices_history_pkey PRIMARY KEY (id);


--
-- Name: devices devices_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);


--
-- Name: dormitories dormitories_alias_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.dormitories
    ADD CONSTRAINT dormitories_alias_key UNIQUE (alias);


--
-- Name: dormitories dormitories_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.dormitories
    ADD CONSTRAINT dormitories_pkey PRIMARY KEY (id);


--
-- Name: duty_hours duty_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.duty_hours
    ADD CONSTRAINT duty_hours_pkey PRIMARY KEY (id);


--
-- Name: faculties faulties_alias_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.faculties
    ADD CONSTRAINT faulties_alias_key UNIQUE (alias);


--
-- Name: faculties faulties_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.faculties
    ADD CONSTRAINT faulties_pkey PRIMARY KEY (id);


--
-- Name: fw_exception_applications fw_exception_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.fw_exception_applications
    ADD CONSTRAINT fw_exception_applications_pkey PRIMARY KEY (id);


--
-- Name: fw_exceptions fw_exceptions_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.fw_exceptions
    ADD CONSTRAINT fw_exceptions_pkey PRIMARY KEY (id);


--
-- Name: campuses id_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.campuses
    ADD CONSTRAINT id_pkey PRIMARY KEY (id);


--
-- Name: inventory_cards_history inventory_cards_history_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.inventory_cards_history
    ADD CONSTRAINT inventory_cards_history_pkey PRIMARY KEY (id);


--
-- Name: inventory_cards inventory_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.inventory_cards
    ADD CONSTRAINT inventory_cards_pkey PRIMARY KEY (id);


--
-- Name: inventory_cards inventory_cards_serial_no_unique; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.inventory_cards
    ADD CONSTRAINT inventory_cards_serial_no_unique UNIQUE (serial_no);


--
-- Name: ipv4s ipv4s_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.ipv4s
    ADD CONSTRAINT ipv4s_pkey PRIMARY KEY (ip);


--
-- Name: locations locations_alias_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_alias_key UNIQUE (alias, dormitory_id);


--
-- Name: locations_history locations_history_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.locations_history
    ADD CONSTRAINT locations_history_pkey PRIMARY KEY (id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: penalties_history penalties_history_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.penalties_history
    ADD CONSTRAINT penalties_history_pkey PRIMARY KEY (id);


--
-- Name: penalties penalties_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.penalties
    ADD CONSTRAINT penalties_pkey PRIMARY KEY (id);


--
-- Name: penalty_templates penalty_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.penalty_templates
    ADD CONSTRAINT penalty_templates_pkey PRIMARY KEY (id);


--
-- Name: penalty_templates penalty_templates_title_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.penalty_templates
    ADD CONSTRAINT penalty_templates_title_key UNIQUE (title);


--
-- Name: radacct_srv radacct_srv_acctsessionid_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radacct_srv
    ADD CONSTRAINT radacct_srv_acctsessionid_key UNIQUE (acctsessionid);


--
-- Name: radacct_srv radacct_srv_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radacct_srv
    ADD CONSTRAINT radacct_srv_pkey PRIMARY KEY (radacctid);


--
-- Name: radacct_sw radacct_sw_acctsessionid_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radacct_sw
    ADD CONSTRAINT radacct_sw_acctsessionid_key UNIQUE (acctsessionid);


--
-- Name: radacct_sw radacct_sw_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radacct_sw
    ADD CONSTRAINT radacct_sw_pkey PRIMARY KEY (radacctid);


--
-- Name: radacct_wifi radacct_wifi_acctsessionid_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radacct_wifi
    ADD CONSTRAINT radacct_wifi_acctsessionid_key UNIQUE (acctsessionid);


--
-- Name: radacct_wifi radacct_wifi_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radacct_wifi
    ADD CONSTRAINT radacct_wifi_pkey PRIMARY KEY (radacctid);


--
-- Name: radius_user_device radius_user_device_pk; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radius_user_device
    ADD CONSTRAINT radius_user_device_pk PRIMARY KEY (id);


--
-- Name: radius_users radius_users_pk; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radius_users
    ADD CONSTRAINT radius_users_pk PRIMARY KEY (id);


--
-- Name: radpostauth_srv radpostauth_srv_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radpostauth_srv
    ADD CONSTRAINT radpostauth_srv_pkey PRIMARY KEY (id);


--
-- Name: radpostauth_sw radpostauth_sw_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radpostauth_sw
    ADD CONSTRAINT radpostauth_sw_pkey PRIMARY KEY (id);


--
-- Name: radpostauth_wifi radpostauth_wifi_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.radpostauth_wifi
    ADD CONSTRAINT radpostauth_wifi_pkey PRIMARY KEY (id);


--
-- Name: switches_firmware switches_firmware_firmware_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_firmware
    ADD CONSTRAINT switches_firmware_firmware_key UNIQUE (firmware);


--
-- Name: switches_firmware switches_firmware_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_firmware
    ADD CONSTRAINT switches_firmware_pkey PRIMARY KEY (id);


--
-- Name: switches_history switches_history_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_history
    ADD CONSTRAINT switches_history_pkey PRIMARY KEY (id);


--
-- Name: switches switches_ipv4_unique; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches
    ADD CONSTRAINT switches_ipv4_unique UNIQUE (ipv4);


--
-- Name: switches_model switches_model_model_no_unique; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_model
    ADD CONSTRAINT switches_model_model_no_unique UNIQUE (model_no);


--
-- Name: switches_model switches_model_name_unique; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_model
    ADD CONSTRAINT switches_model_name_unique UNIQUE (model_name);


--
-- Name: switches_model switches_model_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_model
    ADD CONSTRAINT switches_model_pkey PRIMARY KEY (id);


--
-- Name: switches switches_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches
    ADD CONSTRAINT switches_pkey PRIMARY KEY (id);


--
-- Name: switches_port switches_port_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_port
    ADD CONSTRAINT switches_port_pkey PRIMARY KEY (id);


--
-- Name: text text_alias_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.text
    ADD CONSTRAINT text_alias_key UNIQUE (alias);


--
-- Name: text text_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.text
    ADD CONSTRAINT text_pkey PRIMARY KEY (id);


--
-- Name: users_functions users_functions_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users_functions
    ADD CONSTRAINT users_functions_pkey PRIMARY KEY (id);


--
-- Name: users_history users_history_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users_history
    ADD CONSTRAINT users_history_pkey PRIMARY KEY (id);


--
-- Name: users users_login_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_login_key UNIQUE (login);


--
-- Name: users users_pesel_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pesel_key UNIQUE (pesel);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_tokens users_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users_tokens
    ADD CONSTRAINT users_tokens_pkey PRIMARY KEY (id);


--
-- Name: vlans vlans_name_key; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.vlans
    ADD CONSTRAINT vlans_name_key UNIQUE (name);


--
-- Name: vlans vlans_pkey; Type: CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.vlans
    ADD CONSTRAINT vlans_pkey PRIMARY KEY (id);


--
-- Name: computers_aliases_domain_name_key; Type: INDEX; Schema: public; Owner: sru
--

CREATE UNIQUE INDEX computers_aliases_domain_name_key ON public.computers_aliases USING btree (domain_name);


--
-- Name: computers_domain_name_key; Type: INDEX; Schema: public; Owner: sru
--

CREATE UNIQUE INDEX computers_domain_name_key ON public.computers USING btree (domain_name, active) WHERE (active = true);


--
-- Name: computers_history_ipv4_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX computers_history_ipv4_idx ON public.computers_history USING btree (ipv4);


--
-- Name: computers_ipv4_key; Type: INDEX; Schema: public; Owner: sru
--

CREATE UNIQUE INDEX computers_ipv4_key ON public.computers USING btree (ipv4, active) WHERE (active = true);


--
-- Name: computers_mac_key; Type: INDEX; Schema: public; Owner: sru
--

CREATE UNIQUE INDEX computers_mac_key ON public.computers USING btree (mac, active) WHERE ((active = true) AND (type_id <> 41) AND (type_id <> 42) AND (type_id <> 44));


--
-- Name: dormitories_active_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX dormitories_active_idx ON public.dormitories USING btree (active);


--
-- Name: fki_computers_aliases_fkey; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX fki_computers_aliases_fkey ON public.computers_aliases USING btree (computer_id);


--
-- Name: fki_computers_bans_computer_id; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX fki_computers_bans_computer_id ON public.computers_bans USING btree (computer_id);


--
-- Name: fki_computers_bans_penalty_id; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX fki_computers_bans_penalty_id ON public.computers_bans USING btree (penalty_id);


--
-- Name: fki_penalties_amnesty_by; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX fki_penalties_amnesty_by ON public.penalties USING btree (amnesty_by);


--
-- Name: fki_penalties_created_by; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX fki_penalties_created_by ON public.penalties USING btree (created_by);


--
-- Name: fki_penalties_modified_by; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX fki_penalties_modified_by ON public.penalties USING btree (modified_by);


--
-- Name: fki_penalties_user_id; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX fki_penalties_user_id ON public.penalties USING btree (user_id);


--
-- Name: fki_switches_model_fkey; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX fki_switches_model_fkey ON public.switches USING btree (model);


--
-- Name: fki_switches_port_connected_switch_fkey; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX fki_switches_port_connected_switch_fkey ON public.switches_port USING btree (connected_switch);


--
-- Name: fw_exception_applications_valid_to_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX fw_exception_applications_valid_to_idx ON public.fw_exception_applications USING btree (valid_to);


--
-- Name: fw_exceptions_computer_port_key; Type: INDEX; Schema: public; Owner: sru
--

CREATE UNIQUE INDEX fw_exceptions_computer_port_key ON public.fw_exceptions USING btree (computer_id, port, active) WHERE (active = true);


--
-- Name: idx_duty_hours_admin_id; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX idx_duty_hours_admin_id ON public.duty_hours USING btree (admin_id);


--
-- Name: idx_switches_port_ordinal_no; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX idx_switches_port_ordinal_no ON public.switches_port USING btree (ordinal_no);


--
-- Name: inventory_cards_inventory_no_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX inventory_cards_inventory_no_idx ON public.inventory_cards USING btree (inventory_no);


--
-- Name: radacct_srv_active_user_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radacct_srv_active_user_idx ON public.radacct_srv USING btree (acctsessionid, username, nasipaddress) WHERE (acctstoptime IS NULL);


--
-- Name: radacct_srv_bulk_close; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radacct_srv_bulk_close ON public.radacct_srv USING btree (nasipaddress, acctstarttime) WHERE (acctstoptime IS NULL);


--
-- Name: radacct_srv_calss_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radacct_srv_calss_idx ON public.radacct_srv USING btree (class);


--
-- Name: radacct_srv_start_user_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radacct_srv_start_user_idx ON public.radacct_srv USING btree (acctstarttime, username);


--
-- Name: radacct_sw_active_user_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radacct_sw_active_user_idx ON public.radacct_sw USING btree (acctsessionid, username, nasipaddress) WHERE (acctstoptime IS NULL);


--
-- Name: radacct_sw_bulk_close; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radacct_sw_bulk_close ON public.radacct_sw USING btree (nasipaddress, acctstarttime) WHERE (acctstoptime IS NULL);


--
-- Name: radacct_sw_calss_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radacct_sw_calss_idx ON public.radacct_sw USING btree (class);


--
-- Name: radacct_sw_start_user_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radacct_sw_start_user_idx ON public.radacct_sw USING btree (acctstarttime, username);


--
-- Name: radacct_wifi_active_user_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radacct_wifi_active_user_idx ON public.radacct_wifi USING btree (acctsessionid, username, nasipaddress) WHERE (acctstoptime IS NULL);


--
-- Name: radacct_wifi_bulk_close; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radacct_wifi_bulk_close ON public.radacct_wifi USING btree (nasipaddress, acctstarttime) WHERE (acctstoptime IS NULL);


--
-- Name: radacct_wifi_calss_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radacct_wifi_calss_idx ON public.radacct_wifi USING btree (class);


--
-- Name: radacct_wifi_start_user_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radacct_wifi_start_user_idx ON public.radacct_wifi USING btree (acctstarttime, username);


--
-- Name: radius_user_device_mac_uindex; Type: INDEX; Schema: public; Owner: sru
--

CREATE UNIQUE INDEX radius_user_device_mac_uindex ON public.radius_user_device USING btree (mac);


--
-- Name: radius_users_username_uindex; Type: INDEX; Schema: public; Owner: sru
--

CREATE UNIQUE INDEX radius_users_username_uindex ON public.radius_users USING btree (username);


--
-- Name: radpostauth_srv_username_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radpostauth_srv_username_idx ON public.radpostauth_srv USING btree (username);


--
-- Name: radpostauth_sw_username_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radpostauth_sw_username_idx ON public.radpostauth_sw USING btree (username);


--
-- Name: radpostauth_wifi_username_idx; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX radpostauth_wifi_username_idx ON public.radpostauth_wifi USING btree (username);


--
-- Name: users_functions_user_function_key; Type: INDEX; Schema: public; Owner: sru
--

CREATE UNIQUE INDEX users_functions_user_function_key ON public.users_functions USING btree (user_id, function_id);


--
-- Name: users_registry_no_key; Type: INDEX; Schema: public; Owner: sru
--

CREATE UNIQUE INDEX users_registry_no_key ON public.users USING btree (registry_no);


--
-- Name: users_surname_key; Type: INDEX; Schema: public; Owner: sru
--

CREATE INDEX users_surname_key ON public.users USING btree (surname);


--
-- Name: admins admins_update; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER admins_update AFTER UPDATE ON public.admins FOR EACH ROW EXECUTE PROCEDURE public.admin_update();


--
-- Name: TRIGGER admins_update ON admins; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TRIGGER admins_update ON public.admins IS 'kopiuje dane do historii';


--
-- Name: computers computer_add; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER computer_add AFTER INSERT OR UPDATE ON public.computers FOR EACH ROW EXECUTE PROCEDURE public.computer_add();


--
-- Name: computers computer_add_domain_name; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER computer_add_domain_name BEFORE INSERT ON public.computers FOR EACH ROW EXECUTE PROCEDURE public.computers_add_domain_name();


--
-- Name: computers_bans computer_ban_computers; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER computer_ban_computers AFTER INSERT OR DELETE OR UPDATE ON public.computers_bans FOR EACH ROW EXECUTE PROCEDURE public.computer_ban_computers();


--
-- Name: computers computer_set_domain_name; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER computer_set_domain_name BEFORE UPDATE ON public.computers FOR EACH ROW EXECUTE PROCEDURE public.computers_set_domain_name();


--
-- Name: computers computer_update_location; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER computer_update_location AFTER UPDATE ON public.computers FOR EACH ROW EXECUTE PROCEDURE public.computers_change_location();


--
-- Name: computers computers_counters; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER computers_counters AFTER INSERT OR DELETE OR UPDATE ON public.computers FOR EACH ROW EXECUTE PROCEDURE public.computer_counters();


--
-- Name: computers computers_update; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER computers_update AFTER UPDATE ON public.computers FOR EACH ROW EXECUTE PROCEDURE public.computer_update();


--
-- Name: devices devices_update; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER devices_update AFTER UPDATE ON public.devices FOR EACH ROW EXECUTE PROCEDURE public.device_update();


--
-- Name: TRIGGER devices_update ON devices; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TRIGGER devices_update ON public.devices IS 'kopiuje dane do historii';


--
-- Name: inventory_cards inventory_cards_update; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER inventory_cards_update AFTER UPDATE ON public.inventory_cards FOR EACH ROW EXECUTE PROCEDURE public.inventory_card_update();


--
-- Name: TRIGGER inventory_cards_update ON inventory_cards; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TRIGGER inventory_cards_update ON public.inventory_cards IS 'kopiuje dane do historii';


--
-- Name: ipv4s ipv4s_counters; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER ipv4s_counters AFTER INSERT OR DELETE OR UPDATE ON public.ipv4s FOR EACH ROW EXECUTE PROCEDURE public.ipv4_counters();


--
-- Name: locations locations_counters; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER locations_counters AFTER INSERT OR DELETE OR UPDATE ON public.locations FOR EACH ROW EXECUTE PROCEDURE public.location_counters();


--
-- Name: locations locations_update; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER locations_update AFTER UPDATE ON public.locations FOR EACH ROW EXECUTE PROCEDURE public.location_update();


--
-- Name: TRIGGER locations_update ON locations; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TRIGGER locations_update ON public.locations IS 'kopiuje dane do historii';


--
-- Name: penalties penalties_computers_bans; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER penalties_computers_bans AFTER INSERT OR DELETE OR UPDATE ON public.penalties FOR EACH ROW EXECUTE PROCEDURE public.penalty_computers_bans();


--
-- Name: penalties penalties_update; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER penalties_update AFTER UPDATE ON public.penalties FOR EACH ROW EXECUTE PROCEDURE public.penalty_update();


--
-- Name: TRIGGER penalties_update ON penalties; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TRIGGER penalties_update ON public.penalties IS 'kopiuje dane do historii';


--
-- Name: penalties penalties_users; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER penalties_users AFTER INSERT OR DELETE OR UPDATE ON public.penalties FOR EACH ROW EXECUTE PROCEDURE public.penalty_users();


--
-- Name: switches switches_update; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER switches_update AFTER UPDATE ON public.switches FOR EACH ROW EXECUTE PROCEDURE public.switch_update();


--
-- Name: TRIGGER switches_update ON switches; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TRIGGER switches_update ON public.switches IS 'kopiuje dane do historii';


--
-- Name: users users_computers; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER users_computers AFTER INSERT OR DELETE OR UPDATE ON public.users FOR EACH ROW EXECUTE PROCEDURE public.user_computers();


--
-- Name: users users_counters; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER users_counters AFTER INSERT OR DELETE OR UPDATE ON public.users FOR EACH ROW EXECUTE PROCEDURE public.user_counters();


--
-- Name: users users_update; Type: TRIGGER; Schema: public; Owner: sru
--

CREATE TRIGGER users_update AFTER UPDATE ON public.users FOR EACH ROW EXECUTE PROCEDURE public.user_update();


--
-- Name: TRIGGER users_update ON users; Type: COMMENT; Schema: public; Owner: sru
--

COMMENT ON TRIGGER users_update ON public.users IS 'kopiuje dane do historii';


--
-- Name: admins_dormitories admins_dormitories_admin_id; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.admins_dormitories
    ADD CONSTRAINT admins_dormitories_admin_id FOREIGN KEY (admin) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: admins_dormitories admins_dormitories_dormitory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.admins_dormitories
    ADD CONSTRAINT admins_dormitories_dormitory_id_fkey FOREIGN KEY (dormitory) REFERENCES public.dormitories(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: admins admins_dormitory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_dormitory_id_fkey FOREIGN KEY (dormitory_id) REFERENCES public.dormitories(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: admins_history admins_history_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.admins_history
    ADD CONSTRAINT admins_history_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: admins_history admins_history_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.admins_history
    ADD CONSTRAINT admins_history_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: computers_aliases computers_aliases_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers_aliases
    ADD CONSTRAINT computers_aliases_fkey FOREIGN KEY (computer_id) REFERENCES public.computers(id) ON DELETE CASCADE;


--
-- Name: computers_bans computers_bans_computer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers_bans
    ADD CONSTRAINT computers_bans_computer_id_fkey FOREIGN KEY (computer_id) REFERENCES public.computers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: computers_bans computers_bans_penalty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers_bans
    ADD CONSTRAINT computers_bans_penalty_id_fkey FOREIGN KEY (penalty_id) REFERENCES public.penalties(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: computers computers_carer_id; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers
    ADD CONSTRAINT computers_carer_id FOREIGN KEY (carer_id) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: computers computers_device_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers
    ADD CONSTRAINT computers_device_model_id_fkey FOREIGN KEY (device_model_id) REFERENCES public.device_models(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: computers_history computers_history_computer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers_history
    ADD CONSTRAINT computers_history_computer_id_fkey FOREIGN KEY (computer_id) REFERENCES public.computers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: computers_history computers_history_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers_history
    ADD CONSTRAINT computers_history_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: computers_history computers_history_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers_history
    ADD CONSTRAINT computers_history_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: computers_history computers_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers_history
    ADD CONSTRAINT computers_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: computers computers_inventory_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers
    ADD CONSTRAINT computers_inventory_card_id_fkey FOREIGN KEY (inventory_card_id) REFERENCES public.inventory_cards(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: computers computers_ipv4_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers
    ADD CONSTRAINT computers_ipv4_fkey FOREIGN KEY (ipv4) REFERENCES public.ipv4s(ip) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: computers computers_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers
    ADD CONSTRAINT computers_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: computers computers_master_host_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers
    ADD CONSTRAINT computers_master_host_id_fkey FOREIGN KEY (master_host_id) REFERENCES public.computers(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: computers computers_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers
    ADD CONSTRAINT computers_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.admins(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: computers computers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.computers
    ADD CONSTRAINT computers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: devices devices_device_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_device_model_id_fkey FOREIGN KEY (device_model_id) REFERENCES public.device_models(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: devices_history devices_history_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.devices_history
    ADD CONSTRAINT devices_history_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: devices_history devices_history_device_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.devices_history
    ADD CONSTRAINT devices_history_device_model_id_fkey FOREIGN KEY (device_model_id) REFERENCES public.device_models(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: devices_history devices_history_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.devices_history
    ADD CONSTRAINT devices_history_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: devices_history devices_history_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.devices_history
    ADD CONSTRAINT devices_history_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: devices devices_inventory_card_no_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_inventory_card_no_fkey FOREIGN KEY (inventory_card_id) REFERENCES public.inventory_cards(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: devices devices_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: devices devices_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: dormitories dormitories_campus_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.dormitories
    ADD CONSTRAINT dormitories_campus_id_fkey FOREIGN KEY (campus) REFERENCES public.campuses(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: duty_hours duty_hours_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.duty_hours
    ADD CONSTRAINT duty_hours_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fw_exception_applications fw_exception_applications_skos_opinion_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.fw_exception_applications
    ADD CONSTRAINT fw_exception_applications_skos_opinion_by_fkey FOREIGN KEY (skos_opinion_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fw_exception_applications fw_exception_applications_sspg_opinion_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.fw_exception_applications
    ADD CONSTRAINT fw_exception_applications_sspg_opinion_by_fkey FOREIGN KEY (sspg_opinion_by) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fw_exception_applications fw_exception_applications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.fw_exception_applications
    ADD CONSTRAINT fw_exception_applications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fw_exceptions fw_exceptions_computer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.fw_exceptions
    ADD CONSTRAINT fw_exceptions_computer_id_fkey FOREIGN KEY (computer_id) REFERENCES public.computers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fw_exceptions fw_exceptions_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.fw_exceptions
    ADD CONSTRAINT fw_exceptions_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: inventory_cards inventory_cards_dormitory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.inventory_cards
    ADD CONSTRAINT inventory_cards_dormitory_id_fkey FOREIGN KEY (dormitory_id) REFERENCES public.dormitories(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: inventory_cards_history inventory_cards_history_dormitory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.inventory_cards_history
    ADD CONSTRAINT inventory_cards_history_dormitory_id_fkey FOREIGN KEY (dormitory_id) REFERENCES public.dormitories(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: inventory_cards_history inventory_cards_history_inventory_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.inventory_cards_history
    ADD CONSTRAINT inventory_cards_history_inventory_card_id_fkey FOREIGN KEY (inventory_card_id) REFERENCES public.inventory_cards(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inventory_cards_history inventory_cards_history_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.inventory_cards_history
    ADD CONSTRAINT inventory_cards_history_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: inventory_cards inventory_cards_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.inventory_cards
    ADD CONSTRAINT inventory_cards_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: ipv4s ipv4s_dormitory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.ipv4s
    ADD CONSTRAINT ipv4s_dormitory_id_fkey FOREIGN KEY (dormitory_id) REFERENCES public.dormitories(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: ipv4s ipv4s_vlan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.ipv4s
    ADD CONSTRAINT ipv4s_vlan_id_fkey FOREIGN KEY (vlan) REFERENCES public.vlans(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: locations locations_dormitory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_dormitory_id_fkey FOREIGN KEY (dormitory_id) REFERENCES public.dormitories(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: locations_history locations_history_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.locations_history
    ADD CONSTRAINT locations_history_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: locations_history locations_history_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.locations_history
    ADD CONSTRAINT locations_history_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: penalties penalties_amnesty_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.penalties
    ADD CONSTRAINT penalties_amnesty_by_fkey FOREIGN KEY (amnesty_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: penalties penalties_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.penalties
    ADD CONSTRAINT penalties_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: penalties_history penalties_history_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.penalties_history
    ADD CONSTRAINT penalties_history_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: penalties_history penalties_history_penalty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.penalties_history
    ADD CONSTRAINT penalties_history_penalty_id_fkey FOREIGN KEY (penalty_id) REFERENCES public.penalties(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: penalties penalties_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.penalties
    ADD CONSTRAINT penalties_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: penalties penalties_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.penalties
    ADD CONSTRAINT penalties_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.penalty_templates(id) ON DELETE SET NULL;


--
-- Name: penalties penalties_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.penalties
    ADD CONSTRAINT penalties_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: switches_history switches_history_ipv4_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_history
    ADD CONSTRAINT switches_history_ipv4_fkey FOREIGN KEY (ipv4) REFERENCES public.ipv4s(ip) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: switches_history switches_history_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_history
    ADD CONSTRAINT switches_history_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: switches_history switches_history_model_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_history
    ADD CONSTRAINT switches_history_model_fkey FOREIGN KEY (model) REFERENCES public.switches_model(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: switches_history switches_history_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_history
    ADD CONSTRAINT switches_history_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: switches_history switches_history_switch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_history
    ADD CONSTRAINT switches_history_switch_id_fkey FOREIGN KEY (switch_id) REFERENCES public.switches(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: switches switches_inventory_card_no_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches
    ADD CONSTRAINT switches_inventory_card_no_fkey FOREIGN KEY (inventory_card_id) REFERENCES public.inventory_cards(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: switches switches_ipv4_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches
    ADD CONSTRAINT switches_ipv4_fkey FOREIGN KEY (ipv4) REFERENCES public.ipv4s(ip) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: switches switches_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches
    ADD CONSTRAINT switches_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: switches_model switches_model_firmware_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_model
    ADD CONSTRAINT switches_model_firmware_id_fkey FOREIGN KEY (firmware_id) REFERENCES public.switches_firmware(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: switches switches_model_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches
    ADD CONSTRAINT switches_model_fkey FOREIGN KEY (model) REFERENCES public.switches_model(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: switches switches_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches
    ADD CONSTRAINT switches_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: switches_port switches_port_connected_switch_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_port
    ADD CONSTRAINT switches_port_connected_switch_fkey FOREIGN KEY (connected_switch) REFERENCES public.switches(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: switches_port switches_port_location_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_port
    ADD CONSTRAINT switches_port_location_fkey FOREIGN KEY (location) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: switches_port switches_port_penalty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_port
    ADD CONSTRAINT switches_port_penalty_id_fkey FOREIGN KEY (penalty_id) REFERENCES public.penalties(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: switches_port switches_port_switch_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.switches_port
    ADD CONSTRAINT switches_port_switch_fkey FOREIGN KEY (switch) REFERENCES public.switches(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users users_faculty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_faculty_id_fkey FOREIGN KEY (faculty_id) REFERENCES public.faculties(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: users_functions users_functions_dormitory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users_functions
    ADD CONSTRAINT users_functions_dormitory_id_fkey FOREIGN KEY (dormitory_id) REFERENCES public.dormitories(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: users_functions users_functions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users_functions
    ADD CONSTRAINT users_functions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users_history users_history_faculty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users_history
    ADD CONSTRAINT users_history_faculty_id_fkey FOREIGN KEY (faculty_id) REFERENCES public.faculties(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: users_history users_history_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users_history
    ADD CONSTRAINT users_history_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: users_history users_history_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users_history
    ADD CONSTRAINT users_history_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: users_history users_history_nationality_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users_history
    ADD CONSTRAINT users_history_nationality_id_fkey FOREIGN KEY (nationality) REFERENCES public.countries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: users_history users_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users_history
    ADD CONSTRAINT users_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users users_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: users users_modified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_modified_by_fkey FOREIGN KEY (modified_by) REFERENCES public.admins(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: users users_nationality_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_nationality_id_fkey FOREIGN KEY (nationality) REFERENCES public.countries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: users_tokens users_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sru
--

ALTER TABLE ONLY public.users_tokens
    ADD CONSTRAINT users_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TABLE admins; Type: ACL; Schema: public; Owner: sru
--

GRANT SELECT ON TABLE public.admins TO radius;


--
-- Name: TABLE ipv4s; Type: ACL; Schema: public; Owner: sru
--

GRANT SELECT ON TABLE public.ipv4s TO radius;


--
-- Name: TABLE radacct_srv; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON TABLE public.radacct_srv TO radius;


--
-- Name: SEQUENCE radacct_srv_radacctid_seq; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON SEQUENCE public.radacct_srv_radacctid_seq TO radius;


--
-- Name: TABLE radacct_sw; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON TABLE public.radacct_sw TO radius;


--
-- Name: SEQUENCE radacct_sw_radacctid_seq; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON SEQUENCE public.radacct_sw_radacctid_seq TO radius;


--
-- Name: TABLE radacct_wifi; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON TABLE public.radacct_wifi TO radius;


--
-- Name: SEQUENCE radacct_wifi_radacctid_seq; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON SEQUENCE public.radacct_wifi_radacctid_seq TO radius;


--
-- Name: TABLE radius_user_device; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON TABLE public.radius_user_device TO radius;


--
-- Name: SEQUENCE radius_user_device_id_seq; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON SEQUENCE public.radius_user_device_id_seq TO radius;


--
-- Name: TABLE radius_users; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON TABLE public.radius_users TO radius;


--
-- Name: SEQUENCE radius_users_id_seq; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON SEQUENCE public.radius_users_id_seq TO radius;


--
-- Name: TABLE radpostauth_srv; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON TABLE public.radpostauth_srv TO radius;


--
-- Name: SEQUENCE radpostauth_srv_id_seq; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON SEQUENCE public.radpostauth_srv_id_seq TO radius;


--
-- Name: TABLE radpostauth_sw; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON TABLE public.radpostauth_sw TO radius;


--
-- Name: SEQUENCE radpostauth_sw_id_seq; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON SEQUENCE public.radpostauth_sw_id_seq TO radius;


--
-- Name: TABLE radpostauth_wifi; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON TABLE public.radpostauth_wifi TO radius;


--
-- Name: SEQUENCE radpostauth_wifi_id_seq; Type: ACL; Schema: public; Owner: sru
--

GRANT ALL ON SEQUENCE public.radpostauth_wifi_id_seq TO radius;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: sru
--

GRANT SELECT ON TABLE public.users TO radius;


--
-- Name: TABLE v_admins_cas; Type: ACL; Schema: public; Owner: sru
--

GRANT SELECT ON TABLE public.v_admins_cas TO cas;


--
-- Name: TABLE v_computers; Type: ACL; Schema: public; Owner: sru
--

GRANT SELECT ON TABLE public.v_computers TO radius;


--
-- Name: TABLE v_radcheck_srv; Type: ACL; Schema: public; Owner: sru
--

GRANT SELECT ON TABLE public.v_radcheck_srv TO radius;


--
-- Name: TABLE v_radcheck_sw; Type: ACL; Schema: public; Owner: sru
--

GRANT SELECT ON TABLE public.v_radcheck_sw TO radius;


--
-- Name: TABLE v_radcheck_user; Type: ACL; Schema: public; Owner: sru
--

GRANT SELECT ON TABLE public.v_radcheck_user TO radius;


--
-- Name: TABLE v_radreply; Type: ACL; Schema: public; Owner: sru
--

GRANT SELECT ON TABLE public.v_radreply TO radius;


--
-- Name: TABLE v_radusers; Type: ACL; Schema: public; Owner: sru
--

GRANT SELECT ON TABLE public.v_radusers TO radius;


--
-- Name: TABLE v_radusers2vlans; Type: ACL; Schema: public; Owner: sru
--

GRANT SELECT ON TABLE public.v_radusers2vlans TO radius;


--
-- PostgreSQL database dump complete
--

