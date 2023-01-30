CREATE VIEW OWAP.vwDA_Sessions
AS

SELECT
	AuditID, 
	UserPartyRoleID, 
	SessionID,
	SessionTimeStamp
FROM OWAP.Sessions


