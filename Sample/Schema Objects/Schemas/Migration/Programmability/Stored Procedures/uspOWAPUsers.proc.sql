CREATE PROCEDURE Migration.uspOWAPUsers

AS


-- SET USER PASSWORDS
-- SET SAMW TO BE OWAPAdmin user
UPDATE OWAP.Users
SET UserName = 'OWAPAdmin', Password = 'qmbZRV8gMqLHuRHHWlZbbO5oqs6d7gm5XXyyTXSHGg3Zir1896pP1w==' -- P4ssw0rd
WHERE UserName = 'samw'

UPDATE OWAP.Users
SET Password = '8ogHkRVrCqoFILo9GmvPAMjFGGX0twY6' -- D3llv1sion
WHERE UserName = 'timw'

UPDATE OWAP.Users
SET Password = 'CILwTZG6348vXar2XwXSfCMnfpCY39oRf8oL23LxgDk=' -- 5erv1ce
WHERE UserName = 'clarey'

UPDATE OWAP.Users
SET Password = 'kmN68/C4UHuoqvr6PaBKH20h39DpGlho' -- 17desk@v
WHERE UserName = 'alexg'

UPDATE OWAP.Users
SET Password = '8Vyc0pRZ1GjX9H+WX5R8ar/zVScmWQVo' -- 5qld47am
WHERE UserName = 'dono'

UPDATE OWAP.Users
SET Password = 'Vrv/fRnTAUlVpCsmIDohf7v5pbNT+pRutvmvogayE/U=' -- 4ppl3r@d
WHERE UserName = 'clairl'

UPDATE OWAP.Users
SET Password = 'xk6yvjXbwYtJH6O2ZI4iBiJ0S0g6mkcXU90TlGZpCmU=' -- ll3dpcdk
WHERE UserName = 'attilak'

UPDATE OWAP.Users
SET UserName = 'speacock', Password = 'QbwA+be4f8flAly7l46opmWmFUBykWedpfEk1UzFg2vOC7Z3X0cp4A==' -- P4ssw0rd
WHERE UserName = 'simon.peacock'

	