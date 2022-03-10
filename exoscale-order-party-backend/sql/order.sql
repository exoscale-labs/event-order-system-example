--
-- PostgreSQL database dump
--

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
-- TOC entry 4315 (class 1262 OID 16414)
-- Name: exoscale-order; Type: DATABASE; Schema: -; Owner: avnadmin
--

CREATE DATABASE "exoscale-order" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.UTF-8';


ALTER DATABASE "exoscale-order" OWNER TO avnadmin;

\connect -reuse-previous=on "dbname='exoscale-order'"

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 209 (class 1259 OID 16415)
-- Name: order; Type: TABLE; Schema: public; Owner: avnadmin
--

CREATE TABLE public."order" (
    userid uuid NOT NULL,
    drinkid integer NOT NULL,
    nickname character varying(32) NOT NULL,
    "time" timestamp without time zone
);


ALTER TABLE public."order" OWNER TO avnadmin;

--
-- TOC entry 4169 (class 2606 OID 16419)
-- Name: order order_pkey; Type: CONSTRAINT; Schema: public; Owner: avnadmin
--

ALTER TABLE ONLY public."order"
    ADD CONSTRAINT order_pkey PRIMARY KEY (userid);


-- Completed on 2022-03-09 16:35:21 CET

--
-- PostgreSQL database dump complete
--
