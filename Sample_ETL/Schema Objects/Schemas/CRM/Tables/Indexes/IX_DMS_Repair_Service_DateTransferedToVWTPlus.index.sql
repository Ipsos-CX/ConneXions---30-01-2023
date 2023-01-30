CREATE INDEX [IX_DMS_Repair_Service_DateTransferredToVWTPlus]
    ON [CRM].[DMS_Repair_Service]
	(DateTransferredToVWT)
	INCLUDE(FilteredOut, AuditItemID, DMS_SECON_DEALER_CODE, DMS_SERVICE_ADVISOR_ID, ID)



