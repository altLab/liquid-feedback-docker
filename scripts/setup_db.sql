--
-- Basic database setup for liquid-feedback
--

CREATE USER liquid_feedback WITH
CREATEDB ENCRYPTED PASSWORD 'liquid';

CREATE DATABASE liquid_feedback WITH
OWNER liquid_feedback;

