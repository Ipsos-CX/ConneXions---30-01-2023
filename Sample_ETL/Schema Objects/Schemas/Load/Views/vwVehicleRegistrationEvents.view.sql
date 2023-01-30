CREATE VIEW Load.vwVehicleRegistrationEvents

AS

SELECT DISTINCT
	V.AuditItemID,
	ISNULL(V.MatchedODSVehicleID, 0) AS MatchedODSVehicleID,
	ISNULL(V.ODSRegistrationID, 0) AS ODSRegistrationID,
	ISNULL(V.MatchedODSEventID, 0) AS MatchedODSEventID,
	V.VehicleRegistrationNumber,
	V.RegistrationDate,
	V.RegistrationDateOrig
FROM dbo.VWT V
INNER JOIN (
	SELECT	 MAX(AuditItemID) AS ParentAuditItemID
			,ISNULL(MatchedODSVehicleID, 0) AS MatchedODSVehicleID
			,ISNULL(ODSRegistrationID, 0) AS ODSRegistrationID
			,ISNULL(MatchedODSEventID, 0) AS MatchedODSEventID
	FROM dbo.VWT
	GROUP BY ISNULL(MatchedODSVehicleID, 0)
			,ISNULL(ODSRegistrationID, 0)
			,ISNULL(MatchedODSEventID, 0)
) M ON M.ParentAuditItemID = V.AuditItemID



