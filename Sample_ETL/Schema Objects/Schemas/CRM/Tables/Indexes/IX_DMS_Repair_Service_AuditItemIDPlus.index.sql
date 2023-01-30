CREATE INDEX [IX_DMS_Repair_Service_AuditItemIDPlus]
    ON [CRM].[DMS_Repair_Service]
	(AuditItemID)
	INCLUDE(DMS_TECHNICIAN, DMS_TECHNICIAN_ID)



