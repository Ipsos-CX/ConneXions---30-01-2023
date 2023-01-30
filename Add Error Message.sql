USE master

-- CONNEXIONS ERRORS
EXEC sp_addmessage 50001, 16, N'A general error has occurred - not much help I''m afraid'

-- OWAP ERRORS
-- Login 60001 - 60100
EXEC sp_addmessage 60001, 16, N'OWAP.Login - A user doesn''t existing with the provided username and password combination'
-- Selection Review 60101 - 60200
-- Customer Update 60201 - 60300
EXEC sp_addmessage 60201, 16, N'OWAP.CustomerUpdate - You must provide either a last name or company name to perform a customer search'


