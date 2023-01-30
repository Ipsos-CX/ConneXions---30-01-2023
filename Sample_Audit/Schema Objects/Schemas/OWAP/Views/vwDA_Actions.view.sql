CREATE VIEW OWAP.vwDA_Actions
AS

SELECT
	AI.AuditItemID, 
	AI.AuditID, 
	A.ActionDate, 
	A.UserPartyID, 
	A.UserRoleTypeID
FROM OWAP.Actions A
INNER JOIN dbo.AuditItems AI ON AI.AuditItemID = A.AuditItemID




